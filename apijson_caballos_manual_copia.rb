require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'


@arreglo_base = ["1", "1A", "1X", "2", "2X", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"]
def revisar(dat)
    nuevo_arreglo = []
    @arreglo_base.each{|arr|
     bus =  dat.select {|a| a['letter'] == arr }
     if bus.length > 0
        nuevo_arreglo << bus[0]
     end
    }
    return nuevo_arreglo
end



def buscar_jornada()
    uri = URI("https://api-v3.centerhorses.online/export/day")
    # uri = URI("https://api-race.centerhorses.online/export/day")
    res = Net::HTTP.get(uri)
    datos = JSON.parse(res)
    datos.each{|dat|
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
      dat['races'].sort_by { |hsh| hsh['number'] }.each{|carr|
        numero = carr['number']
        hora_utc = carr['startDate'].gsub(' ','T' ) + "Z"
        hora = (carr['startDate'].gsub(' ','T' ) + "Z").to_time.in_time_zone('America/Caracas')  
        buscar_carrera = buscar_jornada.carrera.where(numero_carrera: numero).last   
 #       unless buscar_carrera
           nueva_carrera =  buscar_jornada.carrera.create(hora_carrera: hora.strftime('%H:%M:%S'), numero_carrera: numero, cantidad_caballos: carr['horses'].count, activo: true, hora_pautada: hora.strftime('%H:%M:%S'), utc: hora_utc)
           revisar(carr['horses']).each{|cab|
           puts "***************************"
           puts buscar_hipodromo.nombre
           puts numero
           puts cab["letter"].to_s.strip.upcase
           puts "***************************"
              puesto = cab["letter"].to_s.strip.upcase == "2B" ? "2X" : cab["letter"].to_s.strip.upcase
              nombre_cab = cab['name']
              ml = cab['ml']
              bus_retirado = cab['scratchIndicator']
              if cab['jockey'].present?
                  jockey = cab['jockey']['name']
                  peso = cab['jockey']['weight']
              else 
                  jockey = ""
                  peso = ""
              end
              retirado = bus_retirado == 'Y' ? true : false
              nueva_carrera.caballos_carrera.create(nombre: nombre_cab, retirado: retirado = false, peso: peso, jinete: jockey, numero_puesto: puesto, ml: ml)
          }

#        end
      }
      
    }
  
end


buscar_jornada()