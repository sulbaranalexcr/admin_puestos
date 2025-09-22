require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
# require_relative 'config/environment'
require_relative '/home/puestos/puestos/puestosadmin/config/environment'
require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'



def pase_correo(error,mensaje)
ErroresSistema.create(app: 3, app_detalle: "Api Caballos", error: error, detalle: mensaje, nivel: 1, reportado: false)
message = <<EOF
From: sulbaranalex@gmail.com
To: sulbaranalex@gmail.com
Subject: Error en el cron #{error}

#{error}
#{mensaje}
EOF

smtp = Net::SMTP.new 'smtp.gmail.com', 587
smtp.enable_starttls
smtp.start('gmail.com', 'unpuestosoporte@gmail.com', 'alex21ss', :login)
smtp.send_message message, 'unpuestosoporte@gmail.com', 'sulbaranalex@gmail.com','rafaeljmorales@gmail.com'
smtp.finish
end


def calcular_hora_verano(fecha)
  end_of_week_2 = Date.civil(Date.today.year, 3, 14)
  second_sunday = end_of_week_2 - end_of_week_2.wday
  end_of_week_1 = Date.civil(Date.today.year, 11, 7)
  first_sunday = end_of_week_1 - end_of_week_1.wday

  fecha_actual = Time.now
  if fecha_actual >= second_sunday and fecha_actual <= first_sunday
    return fecha.to_time + (60*120)
  else
    return fecha.to_time + (60*60)
  end

end



def buscar_jonada()
  datos = buscar_data('jornada')
  begin
    if datos.length > 0
      fecha = datos[0]['Descripcion'][-10..-1]
      fecha_convertida = Date.strptime(fecha, '%m/%d/%Y').strftime('%Y-%m-%d')
      if fecha_convertida == Time.now.strftime('%Y-%m-%d')
         datos_hip = buscar_data('hipodromo')
         if datos_hip.length > 0
          se_creo = crear_hipodromos(datos_hip)
         else
           return {'status' => "FAILD", "msg" => "No hay carreras para la fecha.", "code" => 400}
         end
      else
        return {'status' => "FAILD", "msg" => "No hay jornada para la fecha.", "code" => 400}
      end
    else
      return {'status' => "FAILD", "msg" => "No hay jornada para la fecha.", "code" => 400}
    end
  rescue StandardError  => e
    return {'status' => "FAILD", "msg" => "Error interno.", "code" => 500}
    pase_correo(e.message,e.backtrace.inspect)
  end
end



def crear_hipodromos(data)
  data.each{|dat|
    bus_hip = Hipodromo.find_by(abreviatura: dat['abreviatura'])
    unless bus_hip.present?
      bus_hip = Hipodromo.create(nombre: dat['nombre_hipodromo'], tipo: 2, nombre_largo: dat['nombre_hipodromo'], cantidad_puestos: 4, abreviatura: dat['abreviatura'])
    end
    if bus_hip.activo
        datos_carreras = buscar_data("carrera/#{dat['abreviatura']}")
        if datos_carreras.length > 0
          bus_jor = Jornada.find_by(hipodromo_id: bus_hip.id, fecha: Time.now.all_day)
          unless bus_jor.present?
             bus_jor = Jornada.create(hipodromo_id: bus_hip.id, fecha: Time.now, cantidad_carreras: datos_carreras.length)
          end
          datos_carreras.each{|carr|
            datos_ejemplares = buscar_data("ejemplares/#{dat['abreviatura']}/#{carr['carrera_nro']}")
            buscar_carrera = Carrera.find_by(jornada_id: bus_jor.id, numero_carrera: carr['carrera_nro'])
            unless buscar_carrera.present?
              hora_juega = calcular_hora_verano(carr['PostDateTime'].to_time).strftime('%H:%M')
              buscar_carrera = Carrera.create(jornada_id: bus_jor.id, hora_carrera: hora_juega, numero_carrera: carr['carrera_nro'], cantidad_caballos: datos_ejemplares.length, hora_pautada: hora_juega, activo: true)
              datos_ejemplares.each{|cab|
                CaballosCarrera.create(carrera_id: buscar_carrera.id, nombre: cab['NombreEjemplar'], retirado: cab['Retirado'], numero_puesto: cab['Id_Ejemplar'])
              }
            end
          }
          redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
          horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
          redis.set("cierre_carre",horas_carrera.to_json)
        end
    end
  }
end


def buscar_data(metodo)
  begin
    uri = URI("http://62.171.137.78:8080/api/v1/" + metodo)
    res = Net::HTTP.get(uri)
    datos = JSON.parse(res)['json']
    unless datos.present?
      return []
    end
    if datos.length > 0
      return datos
    else
      return []
    end
  rescue StandardError  => e
    pase_correo(e.message,e.backtrace.inspect)
    return []
  end
end




def retirar_ejemplar(hip_id,carrera_id,caballos)
    todos_caballos_nombre = true
    arreglo_enjuego = []
    arreglo_propuestas = []
    # hipodromo = Carrera.find(carrera_id).jornada.hipodromo
    hipodromo = Hipodromo.find_by(abreviatura: hip_id)
    carrera_bus = Hipodromo.find_by(abreviatura: hip_id).jornada.last.carrera.find_by(numero_carrera: carrera_id)
    cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_bus.id, retirado: false).count - 1
    retirar_tipo = []
      case cantidad_caballos
      when 5
        retirar_tipo = [14,15,16,17]
      when 4
        retirar_tipo = [10,11,12,13,14,15,16,17]
      when 3
        retirar_tipo = [6,7,8,9,10,11,12,13,14,15,16,17]
      when 2
        retirar_tipo = [2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]
      end
    carr =  carrera_bus
    begin
          if caballos.count > 0
              caballos.each{|cab|
                buscar = CaballosCarrera.find_by(carrera_id: carr.id, numero_puesto: cab,retirado: false)
                if buscar.present?
                     buscar.update(retirado: true)
                     #############enjuego###############
                       enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: buscar.id, activa: false, created_at: Time.now.all_day, status: 2).ids, activo: true, created_at: Time.now.all_day)
                     if enjuego.present?
                          enjuego.update_all(activa: false, status: 2, status2: 13)
                          enjuego.each{|enj|
                            enj.propuesta.update(status: 4, status2: 13)
                             arreglo_enjuego << enj.id
                             tipoenjuego = enj.propuesta.tipo_id.to_i
                             tipo_apuesta_enj = TipoApuesta.find(enj.propuesta.tipo_id)
                             id_quien_juega = enj.propuesta.usuarios_taquilla_id
                          if enj.propuesta.accion_id == 1
                             id_quien_banquea = enj.usuarios_taquilla_id
                             monto_banqueado = (enj.propuesta.monto.to_f * tipo_apuesta_enj.forma_pagar.to_f)
                             cuanto_juega = enj.monto.to_f
                          else
                             id_quien_juega = enj.usuarios_taquilla_id
                             id_quien_banquea = enj.propuesta.usuarios_taquilla_id
                             monto_banqueado = enj.propuesta.monto.to_f
                             cuanto_juega = enj.monto.to_f
                          end

                          moneda = enj.propuesta.moneda
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                        }
                     end
                     if retirar_tipo.length > 0
                         enjuego = Enjuego.where(propuesta_id: Propuesta.where(carrera_id: carrera_id, activa: false, created_at: Time.now.all_day, status: 2, tipo_id: retirar_tipo).ids, activo: true, created_at: Time.now.all_day)
                         if enjuego.present?
                              enjuego.update_all(activa: false, status: 2, status2: 7)
                              enjuego.each{|enj|
                                 enj.propuesta.update(status: 4, status2: 7)
                                 arreglo_enjuego << enj.id
                                 tipoenjuego = enj.propuesta.tipo_id.to_i
                                 tipo_apuesta_enj = TipoApuesta.find(enj.propuesta.tipo_id)
                              if enj.propuesta.accion_id == 1
                                 id_quien_juega = enj.propuesta.usuarios_taquilla_id
                                 id_quien_banquea = enj.usuarios_taquilla_id
                                 monto_banqueado = (enj.propuesta.monto.to_f * tipo_apuesta_enj.forma_pagar.to_f)
                                 cuanto_juega = enj.monto.to_f
                              else
                                 id_quien_juega = enj.usuarios_taquilla_id
                                 id_quien_banquea = enj.propuesta.usuarios_taquilla_id
                                 monto_banqueado = enj.propuesta.monto.to_f
                                 cuanto_juega = enj.monto.to_f
                              end

                              moneda = enj.propuesta.moneda
                            OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                            OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                            }
                         end
                     end



                     #############fin enjuego###########
                     prupuestas = Propuesta.where(caballo_id: buscar.id, status: 1, created_at: Time.now.all_day)
                     if prupuestas.present?
                        prupuestas.update_all(activa: false, status: 4)
                        prupuestas.each{|prop|
                          if prop.status == 2 or prop.status == 1
                             prop.update(activa: false, status: 4, status2: 13)
                          end
                          tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
                          arreglo_propuestas << prop.id
                          OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
                        }
                     end

                     if retirar_tipo.length > 0
                         prupuestas = Propuesta.where(carrera_id: carrera_id, status: 1, created_at: Time.now.all_day, tipo_id: retirar_tipo)
                         if prupuestas.present?
                            prupuestas.update_all(activa: false, status: 4)
                            prupuestas.each{|prop|
                              if prop.status == 2 or prop.status == 1
                                 prop.update(activa: false, status: 4, status2: 7)
                              end
                              tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
                              arreglo_propuestas << prop.id
                              OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Revolucion/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
                            }
                         end
                       end

                  end

              }
            begin
                require 'net/http'
                require 'uri'
                uri = URI("http://127.0.0.1:3003/notificaciones/retirar_cabllo")
                res = Net::HTTP.start(uri.host, uri.port, use_ssl: false) do |http|
                  req = Net::HTTP::Post.new(uri)
                  req['Content-Type'] = 'application/json'
                  req.body = {'propuestas_id' => arreglo_propuestas, 'enjuegos_id' => arreglo_enjuego, 'carrera_id' => carr.id}.to_json
                  http.request(req)
                end
                return
            rescue StandardError => e
                pase_correo(e.message,e.backtrace.inspect)
            end
          end
    rescue StandardError => e
        pase_correo(e.message,e.backtrace.inspect)
    end
end


def buscar_caballo_retirado(id_abre,id_race,id_ejemplar)
  buscar_hip = Hipodromo.find_by(abreviatura: id_abre)
  if buscar_hip.present?
      buscar_jornada = buscar_hip.jornada.where(fecha: Time.now.all_day).last
      if buscar_jornada.present?
        buscar_carrera = buscar_jornada.carrera.find_by(numero_carrera: id_race)
        if buscar_carrera.present?
            bus = buscar_carrera.caballos_carrera.find_by(numero_puesto: id_ejemplar)
            if bus.retirado
              # puts "ya fue retirado"
              return true
            else
              # puts "retiradondo"
              return false
            end
        else
          return true
        end
      else
        return true
      end
  else
    return true
  end
end


def buscar_carga()
  datos = buscar_data('jornada')
  begin
    if datos.length > 0
      fecha = datos[0]['Descripcion'][-10..-1]
      fecha_convertida = Date.strptime(fecha, '%m/%d/%Y').strftime('%Y-%m-%d')
      if fecha_convertida == Time.now.strftime('%Y-%m-%d')
         datos_hip = buscar_data('hipodromo')
         unless datos_hip.length > 0
           pase_correo("No hay jornadas","No se encontro jornadas para la fecha #{Time.now}")
         end
      else
        pase_correo("No hay jornadas","No se encontro jornadas para la fecha #{Time.now}")
      end
    else
      pase_correo("No hay jornadas","No se encontro jornadas para la fecha #{Time.now}")
    end
  rescue StandardError  => e
    return {'status' => "FAILD", "msg" => "Error interno.", "code" => 500}
    pase_correo(e.message,e.backtrace.inspect)
  end
end



scheduler = Rufus::Scheduler.new

def scheduler.on_error(job, error)
   pase_correo(error.message,error.backtrace.inspect)
end


scheduler.cron '00 07 * * *' do ###3 llenado
   buscar_jonada()
end

scheduler.cron '00 08 * * *' do ###3 llenado
   buscar_jonada()
end
scheduler.cron '00 09 * * *' do ###3 llenado
   buscar_jonada()
end

scheduler.cron '00 10 * * *' do ###4 llenado
   buscar_jonada()
   buscar_carga()
end




scheduler.every '10s' do |job2|###3 llenado
  begin
      if Time.now.to_time > "08:10"
        job2.pause()
        retirados = buscar_data('retirados')
        caballos = Hash.new
        if retirados.length > 0
          retirados.each{|cab|
            existe = buscar_caballo_retirado(cab['id_abre'],cab['id_race'],cab['Id_Ejemplar'])
            unless existe
                unless caballos.key?(cab['id_abre'])
                  caballos[cab['id_abre']] = Hash.new
                end
                unless caballos[cab['id_abre']].key?(cab['id_race'])
                  caballos[cab['id_abre']][cab['id_race']] = []
                end
                caballos[cab['id_abre']][cab['id_race']] << cab['Id_Ejemplar']
            end
          }
        end
        ActiveRecord::Base.transaction do
          caballos.each{|hip,carrera|
            carrera.each{|carr_num, caballos|
                  retirar_ejemplar(hip,carr_num,caballos)
            }
          }
      end
        # puts Time.now - time
        job2.resume()
      end
  rescue StandardError => e
     job2.resume()
     pase_correo(e.message,e.backtrace.inspect)
  end
end


scheduler.every '30s' do
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  redis.set("carga_caballos", Time.now.to_s)
end





scheduler.join
