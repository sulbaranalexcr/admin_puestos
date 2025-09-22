require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
#  require_relative 'config/environment'
#require_relative '/home/puestos/puestos/puestosadmin/config/environment'
require_relative "/home/admin/puestos/puestosadmin/config/environment"
require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'



def pase_correo(error,mensaje)
ErroresSistema.create(app: 4, app_detalle: "Reloj Deportes", error: error, detalle: mensaje, nivel: 1, reportado: false)
message = <<EOF
From: sulbaranalex@gmail.com
To: sulbaranalex@gmail.com
Subject: Error en el cron #{error}

#{error}
#{mensaje}
EOF

smtp = Net::SMTP.new 'smtp.gmail.com', 587
smtp.enable_starttls
smtp.start('gmail.com', 'unpuestosoporte@gmail.com', 'alex21ss', :login)
smtp.send_message message, 'unpuestosoporte@gmail.com', 'sulbaranalex@gmail.com','rafaeljmorales@gmail.com'
smtp.finish
end

scheduler = Rufus::Scheduler.new

def scheduler.on_error(job, error)
   pase_correo(error.message,error.backtrace.inspect)
end

# scheduler.cron '00 01 * * *' do
#   redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#   redis.del("cierre_deporte")
# end




scheduler.every '20s' do
 juegos_ant = Match.where(activo: true, local: Time.now.all_day).where("local < ?",Time.now).order(:local)
 juegos_ant.each{|match|
    match.update(activo: false)
 }
 match_todos = Match.select(:id, :nombre, :juego_id, :liga_id).where(activo: true).where("local >= ? and local <= ?", Time.now, Time.now.end_of_day).order(:local)

 if juegos_ant.present?
      juegos = juegos_ant.pluck(:id)
      deportes = []
      if JornadaDeporte.where(fecha: Time.now.all_day).present?
        for juego in Juego.all.order(:nombre)
          ligas = []
          for liga in Liga.where(juego_id: juego.juego_id, activo: true).order(:nombre)
            matchs = []
            for match in match_todos.select {|a| a['liga_id'] == liga.liga_id}
              if match['nombre'].length > 0
                matchs << {"id" => match['id'], "nombre" => match['nombre']}
              end
            end
            if matchs.length > 0
              ligas << {"id" => liga.liga_id, "nombre" => liga.nombre, "matchs" => matchs}
            end
          end
            if ligas.length > 0
              deportes << {"id" => juego.juego_id, "nombre" => juego.nombre, "ligas" => ligas}
            end
        end
      end
     ActionCable.server.broadcast "publicas_deporte_channel", { data: {"tipo" => "CLOSE_MATCH", "match_id" => juegos, "data_menu" => deportes}}
     prupuestas = PropuestasDeporte.where(match_id: juegos, activa: true, created_at: Time.now.all_day)
     if prupuestas.present?
        prupuestas.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
        id_usuarios = []
        prupuestas.each{|prop|
          id_usuarios << prop.id_propone
          OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: "Reverso por juego cerrado: #{prop.detalle_jugada}"  , monto: prop.monto, status: 0, moneda: 2, tipo: 2, tipo_app: 2)
        }
        if id_usuarios.length > 0
           usuarios = UsuariosTaquilla.select(:id,:saldo_usd).where(id: id_usuarios.uniq).pluck(:id,:saldo_usd)
           ActionCable.server.broadcast "publicas_deporte_channel", { data: {"tipo" => "UPDATE_SALDOS", "ids" => usuarios} }
        end
     end
 end

end



scheduler.join
