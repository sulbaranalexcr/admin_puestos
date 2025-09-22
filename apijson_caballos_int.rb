require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'

require_relative '/home/puestos/puestos/puestosadmin/config/environment'
# require_relative 'config/environment'

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
  end_of_week_end = Date.civil(Date.today.year, 3, 14)
  second_sunday = end_of_week_end - end_of_week_end.wday
  end_of_week_start = Date.civil(Date.today.year, 11, 7)
  first_sunday = end_of_week_start - end_of_week_start.wday

  fecha_actual = Time.now
  if fecha_actual >= second_sunday && fecha_actual <= first_sunday
    fecha.to_time + (60 * 60)
  else
    fecha.to_time
  end
end

def create_hip(id, api_name, races, country, date)
  hip = Hipodromo.find_by(id_goal: id)
  jornada = create_jornada(hip, races, date) if hip.present?
  return jornada if hip.present?

  insert_hip(id, api_name, races, country, date)
end

def insert_hip(id, api_name, races, country, date)
  hip = Hipodromo.create(nombre: api_name, tipo: 2, nombre_largo: api_name, cantidad_puestos: 4, abreviatura: '',
                         activo: false, pais: country, bandera: "#{country.downcase}.png", id_goal: id)
  create_jornada(hip, races, date)
end

def create_jornada(hip, races, date)
  buscar_jornada = hip.jornada.where(fecha: date.all_day).last
  return buscar_jornada if buscar_jornada.present?

  hip.jornada.create(fecha: date, cantidad_carreras: races)
end

def revisar(dat)
  new_array = []
  @arreglo_base.each do |arr|
    bus = dat.select { |a| a['letter'] == arr }
    new_array << bus[0] if bus.length.positive?
  end
  new_array
end

def create_racer(jornada, race)
  numero = race['name'][/\d+/].to_i
  return if jornada.carrera.where(numero_carrera: numero).last.present?

  hora_juega = calcular_hora_verano(race['datetime'].to_time)

  hora_utc = convert_to_utc(hora_juega)
  hora = hora_utc.to_time.in_time_zone('America/Caracas')

  new_race = jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero,
                                    cantidad_caballos: race['runners'].count, activo: true,
                                    hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc,
                                    distance: race['distance'], name: race['name'].split(/\d/).last.strip,
                                    purse: race['purse'], results: [])
  insert_horse(race, new_race)
end

def convert_to_utc(time)
  # "#{(race['datetime'].to_time - 1.hour).to_s[0, 16].gsub(' ', 'T')}Z"
  "#{(time - 1.hour).to_s[0, 16].gsub(' ', 'T')}Z"
end

def insert_horse(race, new_race)
  race['runners']['horse'].each do |cab|
    next if cab['number'].blank?

    puesto = cab['number'].strip.upcase
    wgt = cab['wgt'] || '' if cab['wgt'].present?
    peso = (wgt.to_i / 2.2046).to_i
    jockey = "#{cab['jockey']} (#{peso} Kg)" || '' if cab['jockey'].present?
    trainer = cab['trainer'] if cab['trainer'].present?
    nombre_cab = cab['name']
    ml = if cab['odds'].present?
           cab['odds']['bookmaker'].key?('fractional') ? calculate_ml(cab['odds']) : ''
         else
           ''
         end
    next if puesto[/scr/i].present?

    new_race.caballos_carrera.create(nombre: nombre_cab, retirado: false, peso: peso, jinete: jockey, entrenador: trainer, numero_puesto: puesto, ml: ml)
  end
end

def calculate_ml(odds)
  return '' unless odds.instance_of?(Hash)

  odds['bookmaker']['fractional'].gsub('-', '/')
end

def calculate_ml_american(odds)
  return '' unless odds.instance_of?(Hash)

  odd = odds['bookmaker']['fractional']
  a, b = odd.split('-')
  res = (a.to_i / b.to_i) * 100
  res.positive? ? "+#{res}" : res.to_s
rescue StandardError => _e
  ''
end

def calculate_ml_decimal(odds)
  return '' unless odds.instance_of?(Hash)

  odd = odds['bookmaker']['fractional']
  a, b = odd.split('-')
  (a.to_i / b.to_i) + 1
end

scheduler = Rufus::Scheduler.new

def scheduler.on_error(_job, error)
  pase_correo(error.message, error.backtrace.inspect)
end

scheduler.cron '00 04 * * *' do ### llenado
  3.times do |tim|
    date = Time.now + tim.days
    %w[usa australia].each do |country|
      uri = URI("https://www.goalserve.com/getfeed/0a0d67dd3da64f48eb9b08d9a3e907ab/racing/#{country}?json=1&date=#{date.strftime('%d.%m.%Y')}")
      res = Net::HTTP.get(uri)
      datos = JSON.parse(res)
      datos['scores']['tournament'].each do |hip|
        # next unless hip['date'] == Time.now.strftime('%d.%m.%Y')

        jornada = create_hip(hip['id'], hip['name'], hip['race'].count, country.upcase, date)
        hip['race'].each do |carr|
          next unless carr.instance_of?(Hash)

          create_racer(jornada, carr)
        end
      end
    end
  end
end

scheduler.every '30s' do
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  redis.set('carga_caballos', Time.now.to_s)
end

scheduler.join
