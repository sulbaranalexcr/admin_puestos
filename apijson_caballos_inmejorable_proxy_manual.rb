require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'
ENV['TZ'] = 'America/Caracas'
@arreglo_base = ["1", "1A", "1B", "1X", "2", "2A", "2B", "2X", "3", "3A", "3B", "3X"] + (4..35).map(&:to_s)

def revisar(dat)
  nuevo_arreglo = []
  @arreglo_base.each{|arr|
    bus =  dat.select {|a| a['programNumber'] == arr }
    if bus.length > 0
      nuevo_arreglo << bus[0]
    end
  }
  return nuevo_arreglo
end


def send_to_admin()
  uri = URI.parse('https://admin.betsolutiongroup.com/proxy_inmejorable')
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.open_timeout = 120 
  https.read_timeout = 120 
  
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => 1, 'secret' => 'losvergatarios', 'tipo' => 2 }.to_json
  response = https.request(req).body
  JSON.parse(response)
end

def buscar_jornada()
    datos = send_to_admin()
    datos['data'].each{|dat| 
    puts dat['trackName']
      abreviacion = dat['trackCode']
      nombre = dat['trackName']
      pais = dat['countryCode']
      buscar_hipodromo = Hipodromo.find_by(abreviatura: abreviacion)
      unless buscar_hipodromo.present?
        cpuestos = pais.match('VEN') ? 5 : 4
        tipo = pais.match('VEN') ? 1 : 2
        pais = pais.match('VEN') ? 'VENEZUELA' : pais
        buscar_hipodromo = Hipodromo.create(nombre: nombre, tipo: tipo, nombre_largo: nombre, cantidad_puestos: cpuestos, abreviatura: abreviacion, activo: false, pais: pais, bandera: "#{pais.downcase}.png", id_goal: dat['id'], id_video: '')
      else
        buscar_hipodromo.update(id_goal: dat['id'])  
      end
      buscar_jornada = buscar_hipodromo.jornada.where(fecha: Time.now.all_day).last
      unless buscar_jornada.present?
        buscar_jornada = buscar_hipodromo.jornada.create(fecha: Time.now, cantidad_carreras: dat['races'].count)
      end
      dat['races'].sort_by { |hsh| hsh['raceNumber'] }.each { |carr|
        Time.zone = 'America/Caracas'
        fecha_local = carr['raceDate']
        numero = carr['raceNumber']
        hora_utc = Time.zone.parse(fecha_local).utc.iso8601
        hora = carr['raceDate'].to_time
        buscar_carrera = buscar_jornada.carrera.where(numero_carrera: numero).last
        unless buscar_carrera
           nueva_carrera =  buscar_jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero, cantidad_caballos: carr['horses'].count, activo: true, hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc, distance: '', name: '',
                                      purse: '', results: [], id_api: "#{Time.now.strftime('%Y%m%d')}-#{abreviacion}-#{numero}", 
                                      hipodromo_id: buscar_hipodromo.id, hipodromo_name: buscar_hipodromo.nombre)
           revisar(carr['horses']).each{|cab|
              puesto = cab["programNumber"].to_s.strip.upcase
              nombre_cab = cab['horseName']
              ml = cab['odd']
              if cab['jockey'].present?
                jockey = cab['jockey']
                peso = ''
              else
                jockey = ''
                peso = ''
              end
              if cab['trainer'].present?
                tra_name = cab['trainer']
              else
                tra_name = ''
              end
    
              retirado = cab['active'] ? false : true
              id_api = "#{Time.now.strftime('%Y%m%d')}-#{abreviacion}-#{numero}-#{puesto}"
              nueva_carrera.caballos_carrera.create(nombre: nombre_cab.titleize, retirado: retirado, peso: peso, jinete: jockey, numero_puesto: puesto, ml: ml, entrenador: tra_name, id_api: id_api)
            }

        end
      }

    }

  end

  buscar_jornada()
