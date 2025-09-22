require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'

@arreglo_base = ['1', '1A', '1X', '2', '2B', '2X', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']

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
  uri = URI("http://165.140.242.22:8090/api/v2/tracks")
  res = Net::HTTP.get(uri)
  JSON.parse(res)
end

def create_hip(id, api_name, races, date, country)
  hip = Hipodromo.find_by(id_goal: id)
  jornada = create_jornada(hip, races, date) if hip.present?
  return jornada if hip.present?

  insert_hip(id, api_name, races, date, country)
end

def insert_hip(id, api_name, races, date, country)
  hip = Hipodromo.create(nombre: api_name, tipo: 2, nombre_largo: api_name, cantidad_puestos: 4, abreviatura: '',
                         activo: false, pais: country, bandera: '', id_goal: id)
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
    numero = race['raceKey']['raceNumber'].to_i
    next if racer_exist?(jornada, numero)

    # hora_juega = calcular_hora_verano(race['postTime'].to_time + 4.hours)
    hora_juega = "#{date.to_s[0,10]} #{race['postTime'].to_time.strftime('%H:%M:%S')}".to_time + 4.hours
    hora_utc = convert_to_utc(hora_juega)
    hora = hora_utc.to_time.in_time_zone('America/Caracas')

    new_race = jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero,
                                      cantidad_caballos: race['runners'].count, activo: true,
                                      hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc,
                                      distance: race['distance'], name: race['raceTypeDescription'],
                                      purse: race['purse'], results: [])
    insert_horse(race, new_race)
  end
end

def convert_to_utc(time)
  # "#{(race['datetime'].to_time - 1.hour).to_s[0, 16].gsub(' ', 'T')}Z"
  "#{time.to_s[0, 16].gsub(' ', 'T')}Z"
end

def insert_horse(race, new_race)
  race['runners'].each do |cab|
    next if cab['programNumber'].blank?

    puesto = cab['programNumber'].strip.upcase
    wgt = cab['weight'] || '' if cab['weight'].present?
    peso = (wgt.to_i / 2.2046).to_i
    jockey = "#{cab['jockey']['firstName'].to_s} #{cab['jockey']['lastName'].to_s}"
    trainer = "#{cab['trainer']['firstName'].to_s} #{cab['trainer']['lastName'].to_s}"
    nombre_cab = cab['horseName']
    ml = if cab['morningLineOdds'].present?
           cab['morningLineOdds']
         else
           ''
         end
    next if cab['scratchIndicator'] != 'N'

    new_race.caballos_carrera.create(nombre: nombre_cab, retirado: false, peso: peso, jinete: jockey,
                                     entrenador: trainer, numero_puesto: puesto, ml: ml)
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
  uri = URI("http://165.140.242.22:8090/api/v2/races?track=#{racecourse['trackId']}")
  res = Net::HTTP.get(uri)
  datos = JSON.parse(res)
  datos['data'].each do |hip|
    next unless hip['race']['races'].length.positive?

    date = DateTime.strptime(hip['date'], '%m-%d-%Y').to_time.beginning_of_day
    jornada = create_hip(racecourse['trackId'], racecourse['trackName'], hip['race']['races'].length, date, racecourse['country'])
    # hip['race']['races'].each do |carr|
    create_racers(jornada, hip['race']['races'], date)
    # end
  end
rescue JSON::ParserError => e
  puts 'Dia no cargado'
end


puts 'Creando carreras para USA'
racecourses = extract_racecourses
racecourses['data'].each do |racecourse|
  execute_insert(racecourse)
end
