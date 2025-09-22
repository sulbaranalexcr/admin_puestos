require 'net/http'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'


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

def deportes(id)
  case id.to_i
  when 1 ### futbol americano
    detalle = [['Straight Up', 'SM', 'Money line'], ['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja']]
    orden = [['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja'], ['Straight Up', 'SM', 'Money line']]
    nombre = 'Futbol Americano'
    objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre }
  when 4 ### Baseball
    detalle = [['Straight Up', 'SM', 'Money line'], ['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja']]
    orden = [['Straight Up', 'SM', 'Money line'], ['Totals', 'PS', 'Alta y Baja'], ['Spread', 'ML', 'Run Line']]
    nombre = 'Beisbol'
    #ojo lko que esta en el parentesis del nombre es el piche,def deportes(idr
    objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre }
  when 5 ### Basketball
    detalle = [['Straight Up', 'SM', 'Money line'], ['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja']]
    orden = [['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja'], ['Straight Up', 'SM', 'Money line']]
    nombre = 'Baloncesto'
    objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre }
  when 12 ###soccer
    detalle = [['Straight Up', 'SM', 'Money line'], ['Totals', 'PS', 'Alta y Baja']]
    orden = [['Straight Up', 'SM', 'Money line'], ['Totals', 'PS', 'Alta y Baja']]
    nombre = 'Soccer'
    objeto = { 'cantidad' => 2, 'orden' => orden, 'tiene_empate' => true, 'nombre' => nombre }
  when 16 ### Ice Hockey
    detalle = [['Straight Up', 'SM', 'Money line'], ['Spread', 'ML', 'Run Line'], ['Totals', 'PS', 'Alta y Baja']]
    orden = [['Straight Up', 'SM', 'Money line'], ['Totals', 'PS', 'Alta y Baja'], ['Spread', 'ML', 'Run Line']]
    nombre = 'Hockey Sobre Hielo'
    objeto = { 'cantidad' => 3, 'orden' => orden, 'tiene_empate' => false, 'nombre' => nombre }
  end
end

def buscar_data(url, date_start, date_end)
  uri = URI("#{url}&date_start=#{date_start}&date_end=#{date_end}")
  res = Net::HTTP.get(uri)
  JSON.parse(res)
end

def crear_liga(id, nombre, juego_id)
  buscar = Liga.find_by(liga_id: id)
  unless buscar.present?
    Liga.create(liga_id: id, nombre: nombre, juego_id: juego_id, activo: false, status: 1)
  end
end

def prepare_data(odds, use_draw, id, nombre_equipo1, nombre_equipo2)
  odd = odds.find{|a| a['id'] == id.to_s}
  return [] unless odd.present?

  odds_filter =  odd['bookmakers'].first['odds']
  return [] unless odds_filter.present?

  final_odds = odds_filter['odds']
  return [] unless final_odds.present?

  home = final_odds.find{|b| b['name'][/home/i]}
  away = final_odds.find{|b| b['name'][/away/i]}
  if use_draw
    draw = final_odds.find{|b| b['name'][/draw/i]}
    [{'i'=> (SecureRandom.random_number(9e9) + 1e9).to_i, 't'=> 'Draw', 'o'=> draw['value'], 'uk'=> '', 'us'=> convertir_logro_a_americano(draw['value'])},
     {'i'=> (SecureRandom.random_number(9e9) + 1e9).to_i, 't'=> nombre_equipo1, 'o'=> home['value'], 'uk'=>'', 'us'=> convertir_logro_a_americano(home['value'])},
     {'i'=> (SecureRandom.random_number(9e9) + 1e9).to_i, 't'=> nombre_equipo2, 'o'=> away['value'], 'uk'=>'', 'us'=> convertir_logro_a_americano(away['value'])}]
  else
    [{'i'=> (SecureRandom.random_number(9e9) + 1e9).to_i, 't'=> nombre_equipo1, 'o'=> home['value'], 'uk'=>'', 'us'=> convertir_logro_a_americano(home['value'])},
     {'i'=> (SecureRandom.random_number(9e9) + 1e9).to_i, 't'=> nombre_equipo2, 'o'=> away['value'], 'uk'=>'', 'us'=> convertir_logro_a_americano(away['value'])}]
  end
end

def crear_match(matches, sport_id, league_id)
  matches.each do |match|
    utc = "#{match['formatted_date'].split('.').reverse.join('-')}T#{match['time']}Z"
    local = utc.to_time.in_time_zone('America/Caracas')
    id = match['id']
    nombre_equipo1 = match['localteam']['name']
    nombre_equipo2 = match['visitorteam']['name']
    nom = "#{nombre_equipo1} vs #{nombre_equipo2}"
    numero_eqp = ''
    unless JornadaDeporte.find_by(juego_id: sport_id, liga_id: league_id, fecha: local.all_day).present?
      JornadaDeporte.create(juego_id: sport_id, liga_id: league_id, fecha: local)
    end
    buscar = Match.find_by(match_id: id, juego_id: juego_id, liga_id: liga_id)
    search_sport = Juego.find(sport_id)
    money_line = prepare_data(match['odds'], search_sport.use_draw, search_sport.data_api['money_line_id'], nombre_equipo1, nombre_equipo2)
    run_line = prepare_data(match['odds'], search_sport.use_draw, search_sport.data_api['run_line_id'], nombre_equipo1, nombre_equipo2)
    alta_baja = prepare_data(match['odds'], search_sport.use_draw, search_sport.data_api['totals_id'], nombre_equipo1, nombre_equipo2)

    objeto = { 'match_id' => id, 'match' => nom, 'deporte_id' => juego_id, 'liga_id' => liga_id, 'local' => local, 'utc' => utc, 'money_line' => money_line, 'run_line' => run_line, 'alta_baja' => alta_baja }.to_json
    if buscar.present?
      buscar.update(utc: utc, local: local, match: [], data: objeto)
      @machts << matchess
    else
      Match.create(match_id: id, id_base: numero_eqp, nombre: nom, utc: utc, local: local, match: [], juego_id: juego_id, liga_id: liga_id, activo: true, status: 1, jornada_id: JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).id, usa_empate: true, data: objeto)
    end
  end
end

def generar_data(res, sport_id)
  res.each do |api|
    crear_liga(api['id'], api['name'], sport_id)
    crear_match(res['maches'])
  end
end

puts 'Comence'
res = buscar_data(url)
generar_data(res['scores']['categories'], sport_id)
puts 'termine'
