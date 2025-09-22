require 'net/http'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'
# require_relative '/home/puestos/puestos/puestosadmin/config/environment'
require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'

@machts = []

@nombre_equipo_traducir = {
  'COL' =>	'COLORADO',
  'ATL' =>	'ATLANTA',
  'PIT' =>	'PIRATAS',
  'SDG' =>	'SAN DIEGO',
  'SFO' =>	'SAN FRANCISCO',
  'MIN' =>	'MINNESOTA',
  'BAL' =>	'BALTIMORE',
  'TOR' =>	'TORONTO',
  'CWS' =>	'CHICAGO WSOX',
  'LAA' =>	'ANAHEIM',
  'CLE' =>	'CLEVELAND',
  'MIL' =>	'MILWAUKEE',
  'WAS' =>	'WASHINGTON',
  'MIA' =>	'MIAMI',
  'CIN' =>	'CINCINNATI',
  'LOS' =>	'LA DODGERS',
  'ARI' =>	'ARIZONA',
  'DET' =>	'DETROIT',
  'TAM' =>	'TAMPA BAY',
  'NYY' =>	'NY YANKEES',
  'KAN' =>	'KANSAS CITY',
  'SEA' =>	'SEATTLE',
  'HOU' =>	'HOUSTON',
  'NYM' =>	'NY METS',
  'PHI' =>	'PHILADELPHIA',
  'OAK' =>	'OAKLAND',
  'BOS' =>	'BOSTON',
  'CHC' =>	'CHICAGO CUBS',
  'STL' =>	'STL LUIS',
  'TEX' =>	'TEXAS'
}

def convertir_logro_a_americano(logro)
  logro = logro.to_f
  if logro < 2
    (100 / (logro.to_f - 1) * -1).round.to_s
  else
    "+#{((logro.to_f - 1) * 100).round}"
  end
end

def traductir_nombres(nombre)
  if @nombre_equipo_traducir.key?(nombre)
    @nombre_equipo_traducir[nombre]
  else
    nombre
  end
end

# def deportes(id)
#   case id.to_i
#   when 1 ### futbol americano
#     detalle = [['Straight Up', 'SM', 'Money line'], ['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja']]
#     orden = [['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja'], ['Straight Up', 'SM', 'Money line']]
#     nombre = 'Futbol Americano'
#     objeto = {'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre}
#   when 4 ### Baseball
#     detalle = [['Straight Up','SM', 'Money line'], ['Spread', 'ML', 'Run Line'],['Totals','PS', 'Alta y Baja']]
#     orden = [['Straight Up','SM', 'Money line'], ['Totals','PS', 'Alta y Baja'],['Spread', 'ML', 'Run Line']]
#     nombre = 'Beisbol'
#     # ojo lko que esta en el parentesis del nombre es el piche,def deportes(idr
#     objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre}
#   when 5 ### Basketball
#     detalle = [['Straight Up','SM', 'Money line'], ['Spread', 'ML', 'Run Line'],['Totals','PS', 'Alta y Baja']]
#     orden = [['Spread', 'ML', 'Run Line'],['Totals','PS', 'Alta y Baja'],['Straight Up','SM', 'Money line']]
#     nombre = 'Baloncesto'
#     objeto = {'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre}
#   when 12 # soccer
#     detalle = [['Straight Up','SM', 'Money line'], ['Totals','PS', 'Alta y Baja']]
#     orden = [['Straight Up','SM', 'Money line'], ['Totals','PS', 'Alta y Baja']]
#     nombre = 'Soccer'
#     objeto = { 'cantidad' => 2, 'orden' => orden, 'tiene_empate' => true, 'nombre' => nombre}
#   when 16 ### Ice Hockey
#     detalle = [['Straight Up','SM', 'Money line'], ['Spread', 'ML', 'Run Line'],['Totals','PS', 'Alta y Baja']]
#     orden = [['Straight Up','SM', 'Money line'], ['Totals','PS', 'Alta y Baja'],['Spread', 'ML', 'Run Line']]
#     nombre = 'Hockey Sobre Hielo'
#     objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre}
#   end
# end

def buscar_data(tiempo)
  apiskeys = [
    '72f7c229-bebe-e911-8aa0-003048dd52d5',
    '8789faad-63bd-e911-8aa0-003048dd52d5',
    '17cdde57-62bd-e911-8aa0-003048dd52d5',
    '17cdde57-62bd-e911-8aa0-003048dd52d5',
    '63720f0b-bebe-e911-8aa0-003048dd52d5',
    '69b1980e-29c1-e911-8aa0-003048dd52d5',
    'f538025a-2ac1-e911-8aa0-003048dd52d5'
  ]

  uri = URI("http://xmlfeed.everygame.eu/xmloddsfeed/v2/json/feed.ashx?apikey=#{apiskeys.sample}&delta=#{tiempo}&includeFraction=true&includeCent=true")
  res = Net::HTTP.get(uri)

  if res.to_s.include?('Please reduce your polling frequency.')
    buscar_data(tiempo)
  else
    res
  end
end

def crear_juego(id, nombre)
  buscar = Juego.find_by(juego_id: id)
  return if buscar.present?

  Juego.create(juego_id: id, nombre: nombre)
end

def crear_liga(id, nombre, juego_id)
  buscar = Liga.find_by(liga_id: id)
  return if buscar.present?

  Liga.create(liga_id: id, nombre: nombre, juego_id: juego_id, activo: false, status: 1)
end

def get_equipo(equipo1,equipo2,liga_id)
  busqueda_equipo1 = Equipo.find_by(nombre_largo: equipo1, liga_id: liga_id)
  busqueda_equipo2 = Equipo.find_by(nombre_largo: equipo2, liga_id: liga_id)
  nombre_corto1 = ''
  nombre_corto2 = ''
  if busqueda_equipo1.present?
    nombre_corto1 = busqueda_equipo1.nombre
  else
    Equipo.create(equipo_id: 0, nombre: equipo1, nombre_largo: equipo1, liga_id: liga_id)
    nombre_corto1 = equipo1
  end
  if busqueda_equipo2.present?
    nombre_corto2 = busqueda_equipo2.nombre
  else
    Equipo.create(equipo_id: 0, nombre: equipo2, nombre_largo: equipo2, liga_id: liga_id)
    nombre_corto2 = equipo2
  end
  [nombre_corto1, nombre_corto2]
end

def crear_match(obj, juego_id, liga_id)
  id = obj['i']
  nom_temp1 = obj['t'].split(/ v /i)
  return if nom_temp1.length < 2

  nombre_equipo1 = ''
  nombre_equipo2 = ''
  if juego_id.to_i == 4
    nombre_equipo1 = traductir_nombres(nom_temp1[0].split(' ')[0])
    nombre_equipo2 = traductir_nombres(nom_temp1[1].split(' ')[0])
  else
    nombre_extraido = get_equipo(nom_temp1[0], nom_temp1[1], liga_id)
    nombre_equipo1 = nombre_extraido[0]
    nombre_equipo2 = nombre_extraido[1]
  end
  nom = "#{nombre_equipo1} vs #{nombre_equipo2}"

  utc = obj['d']
  numero_eqp = obj.key?('r') ? obj['r'] : 0
  local = utc.to_time.in_time_zone('America/Caracas')
  unless JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).present?
    JornadaDeporte.create(juego_id: juego_id, liga_id: liga_id, fecha: local)
  end
  buscar = Match.find_by(match_id: id, juego_id: juego_id, liga_id: liga_id)
  return if buscar.present? && buscar.activo == false

  # if juego_id.to_i == 12
  matchess = obj.to_json
  # else
  #   matchess = obj.to_json
  # end
  money_line = []
  run_line = []
  alta_baja = []
  mat = obj['c'][0..2]

  if mat[0]['t'] == 'Straight Up'
    if mat[0]['c'][0]['t'].strip.upcase == 'DRAW'
      mat[0]['c'][1]['t'] = nombre_equipo1
      mat[0]['c'][2]['t'] = nombre_equipo2
    else
      mat[0]['c'][0]['t'] = nombre_equipo1
      mat[0]['c'][1]['t'] = nombre_equipo2
    end
    money_line = mat[0]
    if money_line.length.positive?
      money_line['c'].each do |mlb|
        mlb['us'] = convertir_logro_a_americano(mlb['o'])
      end
    end
  end

  if mat.length > 1
    case mat[1]['t']
    when 'Spread'
      run_line = mat[1]
    when 'Totals'
      alta_baja = mat[1]
    end
  end

  if mat.length > 2
    case mat[2]['t']
    when 'Spread'
      run_line = mat[2]
    when 'Totals'
      alta_baja = mat[2]
    end
  end

  if run_line.length.positive?
    run_line['c'].each do |rma|
      rma['us'] = convertir_logro_a_americano(rma['o'])
    end
  end

  if alta_baja.length.positive?
    alta_baja['c'].each do |aba|
      aba['us'] = convertir_logro_a_americano(aba['o'])
    end
  end
  new_data_api = { 'match_id' => id, 'match' => nom, 'deporte_id' => juego_id, 'liga_id' => liga_id, 'local' => local, 'utc' => utc, 'money_line' => money_line, 'run_line' => run_line, 'alta_baja' => alta_baja }
  objeto = new_data_api.to_json
  if buscar.present?
    old_data = JSON.parse(buscar.data)
    se_generan_propuestas = !validate_objects(old_data, new_data_api)
    old_money_line = old_data['money_line']
    # objeto['money_line'] = old_money_line if money_line.length.zero?
    buscar.update(nombre: nom, utc: utc, local: local, match: [], data: objeto) if se_generan_propuestas
    @machts << matchess
    if Match.find_by(match_id: id, local: Time.now.all_day).present? && se_generan_propuestas
      PropuestasParaDeportes::Crear.propuestas(buscar.id, juego_id, 'update')
    end
  else
    if juego_id.to_i == 12
      new_match = Match.create(match_id: id, id_base: numero_eqp, nombre: nom, utc: utc, local: local, match: [], juego_id: juego_id, liga_id: liga_id, activo: true, status: 1, jornada_id: JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).id, usa_empate: true, data: objeto)
    else
      buscar_base_id = Match.find_by(juego_id: juego_id, liga_id: liga_id, id_base: numero_eqp, nombre: nom, local: Time.now.all_day)
      unless buscar_base_id.present?
        new_match = Match.create(match_id: id, id_base: numero_eqp, nombre: nom, utc: utc, local: local, match: [], juego_id: juego_id, liga_id: liga_id, activo: true, status: 1, jornada_id: JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).id, usa_empate: false, data: objeto)
      end
    end
    if Match.find_by(match_id: id, local: Time.now.all_day).present?
      PropuestasParaDeportes::Crear.propuestas(new_match.id, juego_id, 'new')
    end
  end
end

def validate_objects(old_data, new_data)
  validate_money_line(old_data, new_data) && validate_run_line(old_data, new_data) && validate_alta_baja(old_data, new_data)
end

def validate_money_line(old_data, new_data)
  return true unless new_data['money_line'].present?
  return false if old_data['money_line'].length.zero?

  Zlib.crc32(old_data['money_line']['c'].to_s) == Zlib.crc32(new_data['money_line']['c'].to_s)
rescue
  false
end

def validate_run_line(old_data, new_data)
  return true unless new_data['run_line'].present?
  return false if old_data['money_line'].length.zero?

  Zlib.crc32(old_data['run_line']['c'].to_s) == Zlib.crc32(new_data['run_line']['c'].to_s)
rescue
  false
end

def validate_alta_baja(old_data, new_data)
  return true unless new_data['alta_baja'].present?
  return false if old_data['money_line'].length.zero?

  Zlib.crc32(old_data['alta_baja']['c'].to_s) == Zlib.crc32(new_data['alta_baja']['c'].to_s)
rescue
  false
end


def generar_data(res)
  JSON.parse(res).each do |api|
    next if api['t'].include?('Futures')
    next unless [1, 4, 5, 8, 12, 16].include?(api['i'])

    crear_juego(api['i'], api['t'])
    api['c'].each do |sub|
      next if sub['t'].include?('Futures')

      crear_liga(sub['i'], sub['t'], api['i'])
      sub['c'].each do |jue|
        next if jue['c'].first['x'] =~ /fr/i

        # utc = jue['d']
        # local = utc.to_time.in_time_zone('America/Caracas')
        # numero_eqp = jue.key?('r') ? jue['r'] : jue['i'].to_s[-3..-1]
        crear_match(jue, api['i'], sub['i'])
      end
    end
  end
end
# def actualizar(machts)
#   Rails.logger.info '###############################################################################################'
#   Rails.logger.info "Hora de actualizacion: #{Time.now}"
#   Rails.logger.info machts
#   Rails.logger.info '###############################################################################################'
# end
# require 'zlib'
# crc32 = Zlib::crc32(res)
# puts crc32

scheduler = Rufus::Scheduler.new

# scheduler.cron '30 07 * * *' do
#   # ActiveRecord::Base.connection.execute("TRUNCATE matches")
#   # ActiveRecord::Base.connection.execute("TRUNCATE equipos")
#   # ActiveRecord::Base.connection.execute("TRUNCATE ligas")
#   # ActiveRecord::Base.connection.execute("TRUNCATE juegos")
#   redis.set("primero", 0)
#   Rails.logger.info "**************************** Iniciando el dia *******************************"
#   res = buscar_data(800)
#   generar_data(res)
#   redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#   redis.set("primero", 1)
# end

scheduler.every '300s' do
  @machts = []
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  buscred = redis.get('primero')
  if buscred.to_i == 1
    res = buscar_data(5)
    generar_data(res)
  end
end

scheduler.every '30s' do
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  redis.set('carga_deportes', Time.now.to_s)
end

scheduler.join
