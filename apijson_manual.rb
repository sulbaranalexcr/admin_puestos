require "net/http"
require "uri"
require "json"
require "pp"
require_relative "config/environment"
@machts = []

# detalle =  [ ["Straight Up","SM", "Money line"], ["Totals","PS", "Alta y Baja"], ["Correct Score","CS"], ["Half Time / Full Time","HF"], ["Half Time Result","HT"], ["Double Chance","DC"],  ["Totals","P1"], ["Draw No Bet","DB"]]

@nombre_equipo_traducir = {
  "COL" => "COLORADO",
  "ATL" => "ATLANTA",
  "PIT" => "PIRATAS",
  "SDG" => "SAN DIEGO",
  "SFO" => "SAN FRANCISCO",
  "MIN" => "MINNESOTA",
  "BAL" => "BALTIMORE",
  "TOR" => "TORONTO",
  "CWS" => "CHICAGO WSOX",
  "LAA" => "ANAHEIM",
  "CLE" => "CLEVELAND",
  "MIL" => "MILWAUKEE",
  "WAS" => "WASHINGTON",
  "MIA" => "MIAMI",
  "CIN" => "CINCINNATI",
  "LOS" => "LA DODGERS",
  "ARI" => "ARIZONA",
  "DET" => "DETROIT",
  "TAM" => "TAMPA BAY",
  "NYY" => "NY YANKEES",
  "KAN" => "KANSAS CITY",
  "SEA" => "SEATTLE",
  "HOU" => "HOUSTON",
  "NYM" => "NY METS",
  "PHI" => "PHILADELPHIA",
  "OAK" => "OAKLAND",
  "BOS" => "BOSTON",
  "CHC" => "CHICAGO CUBS",
  "STL" => "STL LUIS",
  "TEX" => "TEXAS",
}


def convertir_logro_a_americano(logro)
  logro = logro.to_f
  if logro < 2
    resultado  =  (100 / (logro.to_f - 1) * -1).round.to_s
  else
    resultado  =  "+" + ((logro.to_f - 1) * 100).round.to_s
  end
  resultado
end



def traductir_nombres(nombre)
  if @nombre_equipo_traducir.key?(nombre)
    return @nombre_equipo_traducir[nombre]
  else
    return nombre
  end
end

def deportes(id)
  case id.to_i
  when 1 ### futbol americano
    detalle = [["Straight Up", "SM", "Money line"], ["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"]]
    orden = [["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"], ["Straight Up", "SM", "Money line"]]
    nombre = "Futbol Americano"
    objeto = { "cantidad" => 3, "orden" => orden, "tiene_empate" => false, "nombre" => nombre }
  when 4 ### Baseball
    detalle = [["Straight Up", "SM", "Money line"], ["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"]]
    orden = [["Straight Up", "SM", "Money line"], ["Totals", "PS", "Alta y Baja"], ["Spread", "ML", "Run Line"]]
    nombre = "Beisbol"
    #ojo lko que esta en el parentesis del nombre es el piche,def deportes(idr
    objeto = { "cantidad" => 3, "orden" => orden, "tiene_empate" => false, "nombre" => nombre }
  when 5 ### Basketball
    detalle = [["Straight Up", "SM", "Money line"], ["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"]]
    orden = [["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"], ["Straight Up", "SM", "Money line"]]
    nombre = "Baloncesto"
    objeto = { "cantidad" => 3, "orden" => orden, "tiene_empate" => false, "nombre" => nombre }
  when 12 ###soccer
    detalle = [["Straight Up", "SM", "Money line"], ["Totals", "PS", "Alta y Baja"]]
    orden = [["Straight Up", "SM", "Money line"], ["Totals", "PS", "Alta y Baja"]]
    nombre = "Soccer"
    objeto = { "cantidad" => 2, "orden" => orden, "tiene_empate" => true, "nombre" => nombre }
  when 16 ### Ice Hockey
    detalle = [["Straight Up", "SM", "Money line"], ["Spread", "ML", "Run Line"], ["Totals", "PS", "Alta y Baja"]]
    orden = [["Straight Up", "SM", "Money line"], ["Totals", "PS", "Alta y Baja"], ["Spread", "ML", "Run Line"]]
    nombre = "Hockey Sobre Hielo"
    objeto = { "cantidad" => 3, "orden" => orden, "tiene_empate" => false, "nombre" => nombre }
  end
end

def buscar_data(tiempo)
  apiskeys = [
    "72f7c229-bebe-e911-8aa0-003048dd52d5",
    "8789faad-63bd-e911-8aa0-003048dd52d5",
    "17cdde57-62bd-e911-8aa0-003048dd52d5",
    "17cdde57-62bd-e911-8aa0-003048dd52d5",
    "63720f0b-bebe-e911-8aa0-003048dd52d5",
    "69b1980e-29c1-e911-8aa0-003048dd52d5",
    "f538025a-2ac1-e911-8aa0-003048dd52d5",
  ]
  #uri = URI("http://xmlfeed.intertops.com/xmloddsfeed/v2/json/feed.ashx?apikey=63720f0b-bebe-e911-8aa0-003048dd52d5&delta=600&includeFraction=true&includeCent=true")
  uri = URI("http://xmlfeed.everygame.eu/xmloddsfeed/v2/json/feed.ashx?apikey=#{apiskeys.sample}&delta=#{tiempo}&includeFraction=true&includeCent=true")
  res = Net::HTTP.get(uri)

  if res.to_s.include?("Please reduce your polling frequency.")
    Rails.logger.error "**********************  Error al traer datos del API ***************************"
    buscar_data(tiempo)
  else
    # nuevo_archivo = "reporte_#{Time.now.strftime('%s')}.json"
    # File.open(nuevo_archivo, "w+") { |file| file.write(res) }
    return res
  end
end

def crear_juego(id, nombre)
  buscar = Juego.find_by(juego_id: id)
  unless buscar.present?
    Juego.create(juego_id: id, nombre: nombre)
  end
end

# Rails.logger.info "no existe"

def crear_liga(id, nombre, juego_id)
  buscar = Liga.find_by(liga_id: id)
  unless buscar.present?
    Liga.create(liga_id: id, nombre: nombre, juego_id: juego_id, activo: false, status: 1)
  end
end

def get_equipo(equipo1,equipo2,liga_id)
    busqueda_equipo1 = Equipo.find_by(nombre_largo: equipo1, liga_id: liga_id)
    busqueda_equipo2 = Equipo.find_by(nombre_largo: equipo2, liga_id: liga_id)
    nombre_corto1 = ""
    nombre_corto2 = ""
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
    return [nombre_corto1,nombre_corto2]

end

def crear_match(obj, juego_id, liga_id)
  id = obj["i"]
  nom_temp_1 = obj["t"].split(/ v /i)
  if nom_temp_1.length < 2
    return
  end
  nombre_equipo1 = ""
  nombre_equipo2 = ""
  if juego_id.to_i == 4
    nombre_equipo1 = traductir_nombres(nom_temp_1[0].split(" ")[0])
    nombre_equipo2 = traductir_nombres(nom_temp_1[1].split(" ")[0])
    nom = nombre_equipo1 + " vs " + nombre_equipo2
  else
    nombre_extraido = get_equipo(nom_temp_1[0],nom_temp_1[1],liga_id)
    nombre_equipo1 = nombre_extraido[0]
    nombre_equipo2 = nombre_extraido[1]
    nom = nombre_equipo1 + " vs " + nombre_equipo2
  end
  utc = obj["d"]
  numero_eqp = obj.key?("r") ? obj["r"] : 0
  local = utc.to_time.in_time_zone("America/Caracas")
  unless JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).present?
    JornadaDeporte.create(juego_id: juego_id, liga_id: liga_id, fecha: local)
  end
  buscar = Match.find_by(match_id: id, juego_id: juego_id, liga_id: liga_id)
  if juego_id.to_i == 12
    matchess = obj.to_json
  else
    matchess = obj.to_json
  end
  money_line = []
  run_line = []
  alta_baja = []
  mat = obj["c"][0..2]
  if mat[0]["t"] == "Straight Up"
    if mat[0]["c"][0]['t'].strip.upcase == "DRAW"
       mat[0]["c"][1]['t'] = nombre_equipo1
       mat[0]["c"][2]['t'] = nombre_equipo2
       money_line = mat[0]
    else
      mat[0]["c"][0]['t'] = nombre_equipo1
      mat[0]["c"][1]['t'] = nombre_equipo2
      money_line = mat[0]
    end

    if money_line.length > 0
      money_line['c'].each{|mlb|
        mlb['us'] = convertir_logro_a_americano(mlb['o'])
      }
    end
  end
  if mat.length > 1
    if mat[1]["t"] == "Spread"
      run_line = mat[1]
    elsif mat[1]["t"] == "Totals"
      alta_baja = mat[1]
    end
  end
  if mat.length > 2
    if mat[2]["t"] == "Spread"
      run_line = mat[2]
    elsif mat[2]["t"] == "Totals"
      alta_baja = mat[2]
    end
  end

  if run_line.length > 0
    run_line['c'].each{|rma|
      rma['us'] = convertir_logro_a_americano(rma['o'])
    }
  end

  if alta_baja.length > 0
    alta_baja['c'].each{|aba|
      aba['us'] = convertir_logro_a_americano(aba['o'])
    }
  end

  objeto = { "match_id" => id, "match" => nom, "deporte_id" => juego_id, "liga_id" => liga_id, "local" => local, "utc" => utc, "money_line" => money_line, "run_line" => run_line, "alta_baja" => alta_baja }.to_json
  if buscar.present?
    buscar.update(utc: utc, local: local, match: [], data: objeto)
    @machts << matchess
  else
    if juego_id.to_i == 12
      Match.create(match_id: id, id_base: numero_eqp, nombre: nom, utc: utc, local: local, match: [], juego_id: juego_id, liga_id: liga_id, activo: true, status: 1, jornada_id: JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).id, usa_empate: true, data: objeto)
    else
      buscar_base_id = Match.find_by(juego_id: juego_id, liga_id: liga_id, id_base: numero_eqp, nombre: nom)
      unless buscar_base_id.present?
        Match.create(match_id: id, id_base: numero_eqp, nombre: nom, utc: utc, local: local, match: [], juego_id: juego_id, liga_id: liga_id, activo: true, status: 1, jornada_id: JornadaDeporte.find_by(juego_id: juego_id, liga_id: liga_id, fecha: local.all_day).id, usa_empate: false, data: objeto)
      end
    end
  end
end

def generar_data(res)
  @deportes_todos = []
  JSON.parse(res).each { |api|
    puts "0000000000000000000000000000000000000000000000000000000000000000000000000000000"
    puts "Id Deporte: " + api["i"].to_s
    puts "Deporte: " + api["t"]
    @deportes_todos << {"id" => api["i"].to_s, "nombre" => api["t"]}
    unless api["t"].include?("Futures")
      if [1, 4, 5, 8, 12, 16].include?(api["i"])
        crear_juego(api["i"], api["t"])
        puts "0000000000000000000000000000000000000000000000000000000000000000000000000000000"
        api["c"].each { |sub|
          unless sub["t"].include?("Futures")
            crear_liga(sub["i"], sub["t"], api["i"])
            puts "Liga: " + sub["t"]
            puts "------------------------------------------------------------------------------"
            sub["c"].each { |jue|
            next if jue['c'].first['x'] =~ /fr/i

              utc = jue["d"]
              local = utc.to_time.in_time_zone("America/Caracas")
              numero_eqp = jue.key?("r") ? jue["r"] : jue["i"].to_s[-3..-1]
              # crear_equipo(jue['c'],numero_eqp,sub['i'])
              crear_match(jue, api["i"], sub["i"])
              puts "Id: " + jue["i"].to_s
              puts "Match: " + jue["t"].to_s
              puts "Fecha: " + jue["d"].to_s
              puts "Eid: " + jue["eid"].to_s
              puts "..........................................................................."
              pp jue["c"][0]
              puts "..........................................................................."
              # break
            }
            puts "------------------------------------------------------------------------------"
            # break
          end
        }
        # puts "******************************************************************************"
        # # break
      end
    end
  }
end

def actualizar(machts)
  Rails.logger.info "###############################################################################################"
  Rails.logger.info "Hora de actualizacion: #{Time.now}"
  Rails.logger.info machts
  Rails.logger.info "###############################################################################################"
end

puts "Comence"
res = buscar_data(860)
generar_data(res)
actualizar(@machts)
puts "termine"
puts @deportes_todos




