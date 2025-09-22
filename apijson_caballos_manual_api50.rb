require 'uri'
require 'net/http'
require 'net/smtp'
require 'json'
require 'pp'
require_relative 'config/environment'

@arreglo_base = ['1', '1A', '1X', '2', '2B', '2X', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20']

def extract_racecard(date)
  url = URI("https://horse-racing-usa.p.rapidapi.com/racecards?date=#{date}")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request['X-RapidAPI-Key'] = '922ec3f6b0mshd02ac1cc25aa382p18b9acjsn03827851c688'
  request['X-RapidAPI-Host'] = 'horse-racing-usa.p.rapidapi.com'

  response = http.request(request)
  JSON.parse(response.read_body)
end

def extract_race(race_id)
  url = URI("https://horse-racing-usa.p.rapidapi.com/race/#{race_id}")

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(url)
  request['X-RapidAPI-Key'] = '922ec3f6b0mshd02ac1cc25aa382p18b9acjsn03827851c688'
  request['X-RapidAPI-Host'] = 'horse-racing-usa.p.rapidapi.com'

  response = http.request(request)
  JSON.parse(response.read_body)
end

def generate_data_race(data)
  data_total = []
  data.group_by { |a| a['course'] }.first(4).each do |index, value|
    data_total << { name: index, racers: value.sort_by { |b| b['date'] } }
  end
  data_total
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

def create_hip(id, api_name, races, date, country)
  hip = Hipodromo.find_by(nombre: api_name)
  jornada = create_jornada(hip, races, date) if hip.present?
  return jornada if hip.present?

  insert_hip(id, api_name, races, date, country)
end

def insert_hip(id, api_name, races, date, country)
  hip = Hipodromo.create(nombre: api_name, tipo: 2, nombre_largo: api_name, cantidad_puestos: 4, abreviatura: '',
                         activo: false, pais: country, bandera: '')
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

def racer_exist?(jornada, race)
  jornada.carrera.find_by(numero_carrera: race).present?
end

def create_racer(jornada, race)
  numero = race['name'][/\d+/].to_i
  return if racer_exist?(jornada, numero)

  hora_juega = calcular_hora_verano(Time.now.end_of_day)

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
    jockey = cab['jockey'].to_s || '' if cab['jockey'].present?
    trainer = cab['trainer'] if cab['trainer'].present?
    nombre_cab = cab['name']
    ml = if cab['odds'].present?
           cab['odds']['bookmaker'].key?('fractional') ? calculate_ml(cab['odds']) : ''
         else
           ''
         end
    next if puesto[/scr/i].present?

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

def execute_insert
  date = Time.now
  racecards = extract_racecard(date.strftime('%Y-%m-%d'))
  data_racers = generate_data_race(racecards)
  data_racers.each do |course|
    jornada = create_hip('', course[:name], course[:racers].count, date, 'USA')
    course[:racers].each do |race|
      data_race = extract_race(race['id_race'])
      create_racer(jornada, data_race)
    end
  end
rescue JSON::ParserError => _e
  puts 'Dia no cargado'
end

puts 'Creando carreras para USA'
execute_insert
