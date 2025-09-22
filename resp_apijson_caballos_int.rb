require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
# require_relative 'config/environment'
require_relative '/home/puestos/puestos/puestosadmin/config/environment'

require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'

def pase_correo(error, mensaje)
  ErroresSistema.create(app: 3, app_detalle: 'Api Caballos', error: error, detalle: mensaje, nivel: 1, reportado: false)
  message = <<-MENS
  From: sulbaranalex@gmail.com
  To: sulbaranalex@gmail.com
  Subject: Error en el cron #{error}

  #{error}
  #{mensaje}
  MENS

  smtp = Net::SMTP.new 'smtp.gmail.com', 587
  smtp.enable_starttls
  smtp.start('gmail.com', 'unpuestosoporte@gmail.com', 'alex21ss', :login)
  smtp.send_message message, 'unpuestosoporte@gmail.com', 'sulbaranalex@gmail.com', 'rafaeljmorales@gmail.com'
  smtp.finish
end

def calcular_hora_verano(fecha)
  end_of_week2 = Date.civil(Date.today.year, 3, 14)
  second_sunday = end_of_week2 - end_of_week2.wday
  end_of_week1 = Date.civil(Date.today.year, 11, 7)
  first_sunday = end_of_week1 - end_of_week1.wday

  fecha_actual = Time.now
  if fecha_actual >= second_sunday && fecha_actual <= first_sunday
    fecha.to_time + (60 * 120)
  else
    fecha.to_time + (60 * 60)
  end
end

@arreglo_base = %w[1 1A 1X 2 2B 2X 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
def revisar(dat)
  nuevo_arreglo = []
  @arreglo_base.each do |arr|
    bus = dat.select { |a| a['letter'] == arr }
    nuevo_arreglo << bus[0] if bus.length.positive?
  end
  nuevo_arreglo
end

def buscar_jornada
  uri = URI('https://api-v3.centerhorses.online/export/day')
  # uri = URI("https://api-race.centerhorses.online/export/day")
  res = Net::HTTP.get(uri)
  datos = JSON.parse(res)
  datos.each do |dat|
    abreviacion = dat['id']
    nombre = dat['nameFull']
    pais = dat['country']
    buscar_hipodromo = Hipodromo.find_by(abreviatura: abreviacion)
    unless buscar_hipodromo.present?
      buscar_hipodromo = Hipodromo.create(nombre: nombre, tipo: 2, nombre_largo: nombre, cantidad_puestos: 4, abreviatura: abreviacion, activo: false, pais: pais, bandera: "")
    end
    buscar_jornada = buscar_hipodromo.jornada.where(fecha: Time.now.all_day).last
    unless buscar_jornada.present?
      buscar_jornada = buscar_hipodromo.jornada.create(fecha: Time.now, cantidad_carreras: dat['races'].count)
    end
    dat['races'].sort_by { |hsh| hsh['number'] }.each do |carr|
      numero = carr['number']
      hora_utc = "#{carr['startDate'].gsub(' ', 'T')} Z"
      ## ojo to_time.utc.iso8601
      hora = "#{carr['startDate'].gsub(' ', 'T')} Z".to_time.in_time_zone('America/Caracas')
      buscar_carrera = buscar_jornada.carrera.where(numero_carrera: numero).last
      next if buscar_carrera

      nueva_carrera = buscar_jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero, cantidad_caballos: carr['horses'].count, activo: true, hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc)
      # segundos_programados = (nueva_carrera.hora_pautada.to_time - Time.now) - 600
      # if buscar_hipodromo.activo && segundos_programados > 1
      #   AddPropuestasCaballosJobperform_in(segundos_programados.second, { 'carrera_id' => nueva_carrera.id } )
      # end
      revisar(carr['horses']).each do |cab|
        # puesto = cab["letter"].to_s.strip.upcase == "2B" ? "2X" : cab["letter"].to_s.strip.upcase
        puesto = cab['letter'].to_s.strip.upcase
        nombre_cab = cab['name']
        ml = cab['ml']

        if cab['jockey'].present?
          jockey = cab['jockey']['name']
          peso = cab['jockey']['weight']
        else
          jockey = ''
          peso = ''
        end
        # retirado = cab["scratchIndicator"] == "Y" ? true : false
        nueva_carrera.caballos_carrera.create(nombre: nombre_cab, retirado: false, peso: peso, jinete: jockey, numero_puesto: puesto, ml: ml)
      end
    end
  end
end

scheduler = Rufus::Scheduler.new

def scheduler.on_error(_job, error)
  pase_correo(error.message, error.backtrace.inspect)
end

scheduler.cron '00 04 * * *' do ### poner en cierre api true
  Hipodromo.all.update_all(cierre_api: true)
end

scheduler.cron '00 09 * * *' do ### 3 llenado
  buscar_jornada
end

scheduler.every '30s' do
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  redis.set('carga_caballos', Time.now.to_s)
end

scheduler.join
