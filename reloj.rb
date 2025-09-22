# frozen_string_literal: true

require_relative 'config/environment'
include ApplicationHelper
require 'net/http'
require 'rufus-scheduler'
require './retirados.rb'

SISTEMAS = ["https://admin.unpuestos.com/unica/",
            "https://admin.tablasdinamica.com/unica/",
            "https://admin.rojosynegros.com/unica/",
            "https://admin.piramidehipica.com/unica/"]


ENV['TZ'] = 'America/Caracas'
scheduler = Rufus::Scheduler.new

scheduler.cron '00 01 * * *' do
  REDIS.del('cierre_carre')
  REDIS.close
end

scheduler.cron '30 2 * * *' do
  puts 'Cerrando la aplicación...'
  exit
end

scheduler.cron '00 06 * * *' do
  uri = URI('https://smcvenezuela.xyz/dolarsmcbot/binance-api.php')
  res = JSON.parse(Net::HTTP.get(uri))
  ActiveRecord::Base.transaction do
    clp = res['CLP'].to_f.ceil
    ves = res['VES'].to_f.ceil
    UsuariosTaquilla.where(simbolo_moneda_default: 'CLP')
                    .update_all(moneda_default_dolar: clp, jugada_minima_usd: clp) if clp.to_f.positive?
    UsuariosTaquilla.where(simbolo_moneda_default: ['VES', 'VEF'])
                    .update_all(moneda_default_dolar: ves, jugada_minima_usd: ves) if ves.to_f.positive?
    update_tasa(40, clp)
    update_tasa(1, ves)
  end
end

def update_tasa(moneda, monto)
  return if monto <= 0

  ant = HistorialTasa.where(moneda_id: moneda).last
  tasa_ant = ant.present? ? ant.tasa_nueva : 0
  FactorCambio.where(moneda_id: moneda).update_all(valor_dolar: monto)
  HistorialTasa.create(user_id: User.first.id, moneda_id: moneda, tasa_anterior: tasa_ant, tasa_nueva: monto, ip_remota: '', grupo_id: 0, geo: '')
  Grupo.all.each do |grp|
    his = HistorialTasaGrupo.where(grupo_id: grp.id, moneda_id: moneda)
    tasa_ant = his.present? ? his.last.nueva_tasa.to_f : 0
    HistorialTasaGrupo.create(user_id: User.first.id, grupo_id: grp.id, moneda_id: moneda, tasa_anterior: tasa_ant, nueva_tasa: monto) if his.present?
  end
end

# retirado
def send_retirar_sistemas(url, carrera_id, id_api, data_send)
  uri = URI.parse(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => carrera_id, 'id_api' => id_api, 'caballos' => data_send, 'premia_api' => true, 'recibe_puestos' => true }.to_json
  https.request(req)
rescue StandardError => e
  puts e
end

scheduler.every '30s', overlap: false  do
  uri = URI('https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=Corredores')
  res = Net::HTTP.get(uri)
  data = JSON.parse(res)['response']['data']['Corredores']
  racers = data.group_by { |racersx| racersx['raceId'] }
  racers.each do |race, cab|
    data_send = []
    horse_ids = []
    contador = 0
    cab.each do |c|
      data_send << { 'id' => c['programNumber'], 'nombre' => c['runnerName'], 'retirado' => c['runnerStatus'].to_i > 1 }
      horse_ids << c['runnerId'] if c['runnerStatus'].to_i > 1
      contador += 1 if c['runnerStatus'].to_i > 1
    end
    next if contador.zero?
    next if CaballosCarrera.where(id_api: horse_ids, retirado: true).count == horse_ids.length

    carrera_search = Carrera.find_by(id_api: race)
    next unless carrera_search.present?

    next if PremiosIngresado.find_by(carrera_id: carrera_search.id).present?

    Thread.new {
      retirar(carrera_search.id, data_send)
    }
  
    SISTEMAS.each do |sis_url|
      Thread.new { 
        sis_url = "#{sis_url}retirados/retirar"
        send_retirar_sistemas(sis_url, carrera_search.id, carrera_search.id_api, data_send)
      }
    end
  end
  # sch.next_time = Time.now + 30
  # sch.resume
end

# cierre carreras automatico local sin api
scheduler.every '30s', overlap: false  do
  if REDIS.get('cierre_carre')
    horas_carrera = JSON.parse(REDIS.get('cierre_carre'))
    REDIS.close
    horas_min = []
    horas_carrera.each do |hc|
      if hc[1] != ''
        horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1), 'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    end
  else
    horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day, hipodromo_id: Hipodromo.where(cierre_api: false).ids), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
    REDIS.set('cierre_carre', horas_carrera.to_json)
    REDIS.close
    horas_min = []
    horas_carrera.each do |hc|
      if hc[1] != ''
        horas_min << { 'id' => hc[0], 'resta' => ((hc[1] + ':59'.to_time - Time.now.to_time) / 60).round(1), 'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    end
  end
  ActionCable.server.broadcast 'publicas_channel', { data: { 'tipo' => 1, 'hora' => horas_min } }

  #### carreras
  carreras_ant = Carrera.where(activo: true, jornada_id: Jornada.where(fecha: Time.now.all_day, hipodromo_id: Hipodromo.where(cierre_api: false).ids).ids)
                        .where("to_char(to_timestamp(replace(utc, 'Z',''), 'YYYY-MM-DDThh24:mi:ss')::timestamp - interval '4 hours', 'yyyy-mm-dd') = '#{Time.now.strftime('%Y-%m-%d')}'")
                        .where("substr(carreras.hora_carrera,1,5)  <= '#{(Time.now + 20.seconds).strftime('%H:%M:%S')}' and hora_carrera != ''")
                        .order(:hora_carrera)
  carreras_ant.each do |carr|
    carr.update(activo: false)
    Servicios::Carreras.new.cerrar(carr.id, -1)
    Thread.new {
      close_racer(carr)
    }

    SISTEMAS.each do |sis_url|
      Thread.new { 
        sis_url = "#{sis_url}configuracion/cerrar_carrera"
        send_close_sistemas(sis_url, carr.id, carr.id_api)
      }
    end
  end

  if carreras_ant.present?
    horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
    REDIS.set('cierre_carre', horas_carrera.to_json)
    horas_min = []
    horas_carrera.each do |hc|
      if hc[1] != ''
        horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1), 'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    end
  end
  REDIS.close
end

#### cierre carreras apis
scheduler.every '2s', overlap: false  do
  uri = URI('https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=Cierres')
  res = Net::HTTP.get(uri)
  racers = JSON.parse(res)['response']['data']['Resultados']
  racer_ids = []
  racers.each do |racer|
    next if racer['raceStatus'].to_i <= 1

    racer_ids << racer['raceId']
  end

  carreras_ant = Carrera.where(activo: true, id_api: racer_ids)
  if carreras_ant.present?
    carreras_ant.each do |carr|
      next unless carr.jornada.hipodromo.cierre_api
      ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS', "id" => carr.id } }
      carr.update(activo: false)
      # puts "cerrada"
      Servicios::Carreras.new.cerrar(carr.id, -1)
      Thread.new {
        close_racer(carr)
      }

      SISTEMAS.each do |sis_url|
        Thread.new { 
          sis_url = "#{sis_url}configuracion/cerrar_carrera"
          send_close_sistemas(sis_url, carr.id, carr.id_api)
        }
      end
    end
  end
end

def send_close_sistemas(url, carrera_id, id_api)
  uri = URI.parse(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => carrera_id, 'recibe_puestos' => true, 'id_api' => id_api}.to_json
  https.request(req)
rescue StandardError => e
  puts e
end

def close_racer(carrera)
  ActionCable.server.broadcast "web_notifications_banca_channel", { data: { "tipo" => 998877, "id" => carrera.id }}
  sleep 15
  hipodromo_id_buscar = carrera.jornada.hipodromo.id
  id_carrera = carrera.id
  @cierrec_array_cajero = []
  @usuarios_interno_ganan = []
  @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
  # @ids_cajero_externop = ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json
  ids_upadted = ActiveRecord::Base.connection.execute("update propuestas_caballos_puestos set activa = false, status = 4, status2 = 7, updated_at = now() where carrera_id = #{id_carrera} and activa = true and status = 1 returning id")
  prupuestas = PropuestasCaballosPuesto.where(id: ids_upadted.pluck('id'))
  if prupuestas.present?
    prupuestas.each do |prop|
      if prop.id_propone == prop.id_juega
        tra_id = prop.tickets_detalle_id_juega
        ref_id = prop.reference_id_juega
      else
        tra_id = prop.tickets_detalle_id_banquea
        ref_id = prop.reference_id_banquea
      end
      descripcion = "Reverso/No igualada #{prop.texto_jugada}"
      # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
      #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
      # busca_user = buscar_cliente_cajero(prop.id_propone)
      # if busca_user != '0'
      busca_user = UsuariosTaquilla.find(prop.id_propone)
      if busca_user.usa_cajero_externo
        set_envios_api(4, [busca_user.cliente_id, busca_user.id], tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualada')
      end
    end
  end

  ids_upadted = ActiveRecord::Base.connection.execute("update propuestas_caballos set activa = false, status = 4, status2 = 7, updated_at = now() where carrera_id = #{id_carrera} and activa = true and status = 1 returning id")
  prupuestas_logros = PropuestasCaballo.where(id: ids_upadted.pluck('id'))
  if prupuestas_logros.present?
    prupuestas_logros.each do |prop|
      if prop.id_propone == prop.id_juega
        tra_id = prop.tickets_detalle_id_juega
        ref_id = prop.reference_id_juega
      else
        tra_id = prop.tickets_detalle_id_banquea
        ref_id = prop.reference_id_banquea
      end
      descripcion = "Reverso/No igualada #{prop.texto_jugada}"
      # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
      #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
      busca_user = buscar_cliente_cajero(prop.id_propone)
      if busca_user != '0'
        set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualada')
      end
    end
  end
  PremiacionApiJob.perform_async @cierrec_array_cajero, hipodromo_id_buscar, id_carrera, 4
end

# scheduler.every '30s' do
#   redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#   REDIS.set('reloj_caballos', Time.now.to_s)
# end

scheduler.join
