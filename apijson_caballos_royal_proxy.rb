require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'
require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'
@arreglo_base = [ "1", "1A", "1B", "1X", "2", "2A", "2B", "2X", "3", "3A", "3B", "3X"] + (4..35).map(&:to_s)

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

def extract_racecourses
  send_to_admin(1, '')
end

def extract_runners(race_id)
  send_to_admin(2, race_id)
end


def create_hip(id, api_name, races, date, country)
  hip = Hipodromo.find_by(id_goal: id)
  jornada = create_jornada(hip, races, date) if hip.present?
  return jornada if hip.present?

  insert_hip(id, api_name, races, date, country)
end

def insert_hip(id, api_name, races, date, country)
  country = case country.downcase
            when 'us'
              ['USA', 4]
            when 've'
              ['VENEZUELA', 5]
            when 'no'
              ['NORUEGA', 3]
            when 'gb'
              ['GB', 3]
            when 'sw'
              ['SW', 3]
            when 'nz'
              ['NZ', 3]
            when 'fr'
              ['FR', 3]
            when 'za'
              ['ZA', 3]
            when 'au'
              ['AU', 3]
            when 'ca'
              ['CA', 3]
            else
              [country.upcase, 3]
            end


  hip = Hipodromo.create(nombre: api_name, tipo: 2, nombre_largo: api_name, cantidad_puestos: country[1], abreviatura: '',
                         activo: false, pais: country[0], bandera: "#{country[0].downcase}.png", id_goal: id)
  create_jornada(hip, races, date)
end

def create_jornada(hip, races, date)
  buscar_jornada = hip.jornada.where(fecha: date.all_day).last
  return buscar_jornada if buscar_jornada.present?

  hip.jornada.create(fecha: date + 5.hours, cantidad_carreras: races)
end

def revisar(dat)
  new_array = []
  @arreglo_base.each do |arr|
    bus = dat.select { |a| a['letter'] == arr }
    new_array << bus[0] if bus.length.positive?
  end
  new_array
end

def racer_exist?(jornada, race)
  jornada.carrera.find_by(numero_carrera: race).present?
end

def create_racers(jornada, racers, date)
  racers.each do |race|
    numero = race['raceNumber'].to_i
    next if racer_exist?(jornada, numero)

    # hora_juega = calcular_hora_verano(race['postTime'].to_time + 4.hours)
    hora_juega = race['postTime'].to_time + 4.hours
    hora_utc = convert_to_utc(hora_juega)
    hora = hora_utc.to_time.in_time_zone('America/Caracas')
    runners = extract_runners(race['raceId'])
    new_race = jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero,
                                      cantidad_caballos: runners.count, activo: true,
                                      hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc,
                                      distance: race['distance'], name: race['raceName'],
                                      purse: '', results: [], id_api: race['raceId'],
                                      hipodromo_id: jornada.hipodromo.id, hipodromo_name: jornada.hipodromo.nombre) 
    insert_horse(runners, new_race)
  end
end

def convert_to_utc(time)
  # "#{(race['datetime'].to_time - 1.hour).to_s[0, 16].gsub(' ', 'T')}Z"
  "#{time.to_s[0, 16].gsub(' ', 'T')}Z"
end

def insert_horse(runners, new_race)
  new_horses = []
  @arreglo_base.each do |arre_cab|
    find_horse = runners.find { |hor| hor['programNumber'] == arre_cab }
    next unless find_horse

    new_horses << find_horse
  end

  new_horses.each do |runner|
    next if runner['programNumber'].blank?

    puesto = runner['programNumber'].strip.upcase
    peso = 0 # (wgt.to_i / 2.2046).to_i
    jockey = runner['jockey']
    trainer = runner['trainer']
    runner_name = runner['runnerName'].titleize
    ml = ''
    retirado = runner['runnerStatus'].to_i == 2
    new_race.caballos_carrera.create(nombre: runner_name, retirado: retirado, peso: peso, jinete: jockey,
                                     entrenador: trainer, numero_puesto: puesto, ml: ml, id_api: runner['runnerId'])
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

def execute_insert(racecourse)
  datos = send_to_admin(3, racecourse)

  date = DateTime.strptime(racecourse['cardDate'], '%Y-%m-%d').to_time.beginning_of_day
  return unless %w[US VE GB AU CA].include?(racecourse['countryCode'])

  jornada = create_hip(racecourse['cardId'][4..10].strip, racecourse['cardName'], datos['response']['data']['Carreras'].length, date, racecourse['countryCode'])
  create_racers(jornada, datos['response']['data']['Carreras'], date)
rescue JSON::ParserError => e
  puts e
  puts 'Dia no cargado'
end

def create_filled_hip
  racecourses = extract_racecourses
  racecourses.each do |racecourse|
    execute_insert(racecourse)
  end
end

def send_to_admin(tipo, id)
  uri = URI.parse('https://admin.betsolutionsgroup.com/proxy/request_proxy')
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.open_timeout = 120 
  https.read_timeout = 120 
  
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => id, 'secret' => 'losvergatarios', 'tipo' => tipo }.to_json
  response = https.request(req).body
  JSON.parse(response)
end


scheduler = Rufus::Scheduler.new

scheduler.cron '00 07 * * *' do ### llenado
  create_filled_hip
  # Hipodromo.all.update_all(activo: false)
end

scheduler.cron '00 08 * * *' do ### llenado
  create_filled_hip
end

scheduler.cron '30 08 * * 6,7' do ### llenado
  create_filled_hip
end

scheduler.cron '00 09 * * *' do ### llenado
  create_filled_hip
end

scheduler.cron '30 09 * * 6,7' do ### llenado
  create_filled_hip
end

scheduler.cron '00 10 * * *' do ### llenado
  create_filled_hip
end

scheduler.cron '20 10 * * 6,7' do ### llenado
  create_filled_hip
end

scheduler.cron '30 10 * * 6,7' do ### llenado
  create_filled_hip
end

scheduler.cron '00 11 * * 6,7' do ### llenado
  create_filled_hip
end

scheduler.join
