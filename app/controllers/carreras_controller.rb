class CarrerasController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :json, :html
  before_action :check_user_auth, only: [:show, :index]

  before_action :seguridad_cuentas, only: [:index]

  # before_action :set_carrera, only: [:show, :edit, :update, :destroy]

  def index
    @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.beginning_of_day..(Time.now + 5.days)).pluck(:hipodromo_id))
  end

  def consultar_llaves
    carreras = Carrera.where(created_at: Time.now.all_day)
    carrercas_array = []
    carreras.each { |car|
      carrercas_array << car.id if car.caballos_carrera.pluck(:numero_puesto).any?{ |a| a.match(/^\d[a-zA-Z]+$/) }
    }
    @carreras = Carrera.where(id: carrercas_array.uniq).order(:hora_carrera)
  end

  def detalle
    @caballos = Carrera.find(params[:id]).caballos_carrera.order(:id)
    render partial: "cuerpo_detalle"
  end

  def retirar(carrera_id, caballos_todos)
    caballos = caballos_todos
    arreglo_enjuego = []
    arreglo_propuestas = []
    hipodromo = Carrera.find(carrera_id).jornada.hipodromo
    cantidad_caballos = CaballosCarrera.where(carrera_id: Carrera.find(carrera_id).id, retirado: false).count - 1
    retirar_tipo = []
    ####################

    case cantidad_caballos
    when 5
      retirar_tipo = [14, 15, 16, 17]
    when 4
      retirar_tipo = [10, 11, 12, 13, 14, 15, 16, 17]
    when 3
      retirar_tipo = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    when 2
      retirar_tipo = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    end

    ####################

    carr = Carrera.find(carrera_id)
    begin
      if caballos.count > 0
        caballos.each { |cab|
          buscar = CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab["id"], retirado: false)
          if buscar.present?
            if cab["retirado"]
              buscar.update(retirado: true)
              #############enjuego###############
              enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: buscar.id, activa: false, created_at: Time.now.all_day, status: 2).ids, activo: true, created_at: Time.now.all_day)
              if enjuego.present?
                enjuego.update_all(activa: false, status: 2, status2: 13, updated_at: DateTime.now)
                enjuego.each { |enj|
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
                  # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Reverso/Retirado: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                  # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Reverso/Retirado: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                }
              end
              if retirar_tipo.length > 0
                enjuego = Enjuego.where(propuesta_id: Propuesta.where(carrera_id: carrera_id, activa: false, created_at: Time.now.all_day, status: 2, tipo_id: retirar_tipo).ids, activo: true, created_at: Time.now.all_day)
                if enjuego.present?
                  enjuego.update_all(activa: false, status: 2, status2: 7, updated_at: DateTime.now)
                  enjuego.each { |enj|
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
                    # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Devuelto/Retiro: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                    # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Devuelto/Retiro: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                  }
                end
              end
              #############fin enjuego###########

              prupuestas = Propuesta.where(caballo_id: buscar.id, status: 1, created_at: Time.now.all_day)
              if prupuestas.present?
                prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
                prupuestas.each { |prop|
                  if prop.status == 2 or prop.status == 1
                    prop.update(activa: false, status: 4, status2: 13)
                  end
                  tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
                  arreglo_propuestas << prop.id
                  # OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Reverso/Retirado: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
                }
              end

              if retirar_tipo.length > 0
                prupuestas = Propuesta.where(carrera_id: carrera_id, status: 1, created_at: Time.now.all_day, tipo_id: retirar_tipo)
                if prupuestas.present?
                  prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
                  prupuestas.each { |prop|
                    if prop.status == 2 or prop.status == 1
                      prop.update(activa: false, status: 4, status2: 7)
                    end
                    tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
                    arreglo_propuestas << prop.id
                    # OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Devolucion/Retirado: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
                  }
                end
              end
            end
          end
        }
        begin
          require "net/http"
          require "uri"
          uri = URI("http://127.0.0.1:3003/notificaciones/retirar_cabllo")
          res = Net::HTTP.start(uri.host, uri.port, use_ssl: false) do |http|
            req = Net::HTTP::Post.new(uri)
            req["Content-Type"] = "application/json"
            req.body = { "propuestas_id" => arreglo_propuestas, "enjuegos_id" => arreglo_enjuego, "carrera_id" => carrera_id }.to_json
            http.request(req)
          end
          return
        rescue StandardError => e
          puts e.backtrace.inspect
        end
      end
    rescue Exception => e
    end
  end

  def update_redis_horas
    horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
    REDIS.set("cierre_carre", horas_carrera.to_json)
    REDIS.close
    horas_min = []
    horas_carrera.each { |hc|
      if hc[1] != ""
        horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    }
    # ActionCable.server.broadcast "publicas_channel",data: {"tipo" => 1, "hora" => horas_min}
  end

  def buscar_jornadas
    jornadas = Jornada.where(hipodromo_id: params[:id].to_i, fecha: (Time.now - 1.day).beginning_of_day..(Time.now + 5.days)).order(:fecha)
    if jornadas.present?
      render json: { "jornadas" => jornadas }, methods: [:fecha_bonita]
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def buscar_carreras
    cantidad_carreras = Carrera.where(jornada_id: params[:id].to_i, id: CaballosCarrera.where(carrera_id: Carrera.where(jornada_id: params[:id].to_i).pluck(:id)).pluck(:carrera_id)).order(:id).pluck(:numero_carrera)
    carreras = Carrera.where(jornada_id: params[:id].to_i).order(:id)
    premios = PremiosIngresado.where(jornada_id: params[:id].to_i).to_a
    carreras = carreras.each { |car|
      bus = premios.select { |item| item["carrera_id"].to_i == car.id }
      if bus.present?
        car.numero_carrera = car.numero_carrera + " Premiada"
        car.premiada = true
      else
        car.premiada = false
      end
    }
    if carreras.present?
      render json: { "carreras" => carreras, "cantidad_carreras" => cantidad_carreras }, methods: [:premiada]
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def buscar_caballos
    caballos = CaballosCarrera.where(carrera_id: params[:id]).order(:id)
    @a1 = false
    @x1 = false
    @b2 = false
    @x2 = false
    if caballos.present?
      caballos.each { |buscab|
        if buscab.numero_puesto == "1A"
          @a1 = true
        end
        if buscab.numero_puesto == "1X"
          @x1 = true
        end
        if buscab.numero_puesto == "2B"
          @b2 = true
        end
        if buscab.numero_puesto == "2X"
          @x2 = true
        end
      }
      carrera = Carrera.find(params[:id])
      render json: { "status" => "OK", "cantidad" => caballos.last.numero_puesto, "hora" => carrera.hora_carrera[0, 5], "a1" => @a1, "x1" => @x1, "b2" => @b2, "x2" => @x2 }
    else
      render json: { "status" => "FAILD" }
    end
  end

  def crear_caballos
    carrera_id = params[:id].to_i
    cantidad = params[:cantidad].to_i
    a1 = params[:a1]
    x1 = params[:x1]
    b2 = params[:b2]
    x2 = params[:x2]
    caballos = CaballosCarrera.where(carrera_id: params[:id]).order(:id)
    @caballos_array = []
    cantidad_total = 0
    @esupdate = false
    if caballos.present?
      @esupdate = true
      caballos.each { |ca|
        @caballos_array << { "numero_puesto" => ca.numero_puesto, "nombre" => ca.nombre, "retirado" => ca.retirado, "jinete" => ca.jinete, "entrenador" => ca.entrenador }
        cantidad_total = ca.numero_puesto.to_i
      }
      if cantidad > cantidad_total.to_i
        (cantidad - cantidad_total.to_i).times { |ca|
          @caballos_array << { "numero_puesto" => cantidad_total.to_i + 1, "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
          cantidad_total += 1
        }
      end
    else
      cantidad.times { |ca|
        @caballos_array << { "numero_puesto" => ca + 1, "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
        if a1 and ca + 1 == 1
          @caballos_array << { "numero_puesto" => "1A", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
          if x1
            @caballos_array << { "numero_puesto" => "1X", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
          end
        else
          if a1 and ca + 1 == 2
            if b2
              @caballos_array << { "numero_puesto" => "2B", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
            end
            if x2
              @caballos_array << { "numero_puesto" => "2X", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => '' }
            end
          end
        end
      }
    end
    render partial: "carreras/caballos", layout: false
  end

  def crear_caballos2
    carrera_id = params[:id].to_i
    cantidad = params[:cantidad].to_i
    a1 = params[:a1]
    x1 = params[:x1]
    b2 = params[:b2]
    x2 = params[:x2]
    @caballos_array = []
    cantidad_total = 0
    @esupdate = false

    cantidad.times { |ca|
      bus = CaballosCarrera.find_by(carrera_id: params[:id], numero_puesto: ca + 1)
      if bus.present?
        @caballos_array << { "numero_puesto" => bus.numero_puesto, "nombre" => bus.nombre, "retirado" => bus.retirado, "jinete" => bus.jinete, "entrenador" => bus.entrenador }
      else
        @caballos_array << { "numero_puesto" => ca + 1, "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => ''  }
      end
      if a1 and ca + 1 == 1
        bus = CaballosCarrera.find_by(carrera_id: params[:id], numero_puesto: "1A")
        if bus.present?
          @caballos_array << { "numero_puesto" => "1A", "nombre" => bus.nombre, "retirado" => bus.retirado, "jinete" => bus.jinete, "entrenador" => bus.entrenador }
        else
          @caballos_array << { "numero_puesto" => "1A", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => ''  }
        end
        if x1
          bus = CaballosCarrera.find_by(carrera_id: params[:id], numero_puesto: "1X")
          if bus.present?
            @caballos_array << { "numero_puesto" => "1X", "nombre" => bus.nombre, "retirado" => bus.retirado, "jinete" => bus.jinete, "entrenador" => bus.entrenador }
          else
            @caballos_array << { "numero_puesto" => "1X", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => ''  }
          end
        end
      else
        if ca + 1 == 2
          if b2
            bus = CaballosCarrera.find_by(carrera_id: params[:id], numero_puesto: "2B")
            if bus.present?
              @caballos_array << { "numero_puesto" => "2B", "nombre" => bus.nombre, "retirado" => bus.retirado, "jinete" => bus.jinete, "entrenador" => bus.entrenador }
            else
              @caballos_array << { "numero_puesto" => "2B", "nombre" => "", "retirado" => false, "jinete" => '', "entrenador" => ''  }
            end
          end
          if x2
            bus = CaballosCarrera.find_by(carrera_id: params[:id], numero_puesto: "2X")
            if bus.present?
              @caballos_array << { "numero_puesto" => "2X", "nombre" => bus.nombre, "retirado" => bus.retirado, "jinete" => bus.jinete, "entrenador" => bus.entrenador }
            else
              @caballos_array << { "numero_puesto" => "2X", "nombre" => "", "retirado" => false, 'jinete' => '', 'entrenador' => ''  }
            end
          end
        end
      end
    }
    render partial: "carreras/caballos", layout: false
  end

  def crear_final_carrera
    carrera_id = params[:id]
    caballos = params[:caballos]
    todos_caballos_nombre = true
    modificar = params[:modificar]

    if caballos.length != CaballosCarrera.where(carrera_id: carrera_id).count
      propuestas = Propuesta.where(carrera_id: carrera_id, created_at: Time.now.all_day)
      if propuestas.present?
        datos = []
        CaballosCarrera.where(carrera_id: carrera_id).each { |cab|
          datos << { "id" => cab.numero_puesto, "retirado" => true }
        }
        retirar(carrera_id, datos)
        # CaballosCarrera.where(carrera_id: carrera_id).delete_all
      end
      CaballosCarrera.where(carrera_id: carrera_id).delete_all
    end
    #begin
      carrera = Carrera.find(carrera_id)
      hipodromo_search = carrera.jornada.hipodromo
      abreviacion = hipodromo_search.abreviatura
      carrera.update(hora_carrera: params[:hora] + ":59", hora_pautada: params[:hora] + ":59", utc: (params[:hora] + ":59").to_time.utc, distance: params[:distancia], name: params[:nombre_carrera], purse: params[:purse],
                                      id_api: "#{Time.now.strftime('%Y%m%d')}-#{abreviacion}-#{carrera.numero_carrera}", 
                                      hipodromo_id: hipodromo_search.id, hipodromo_name: hipodromo_search.nombre)

      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_HIPODROMO", "data_menu" => menu_hipodromos_helper(), "hip_id" => Carrera.find(carrera_id).jornada.hipodromo.id } }
      if caballos.count > 0
        caballos.each { |cab|
          if cab["nombre"].to_s.strip.length <= 0
            todos_caballos_nombre = false
          end
        }
        unless todos_caballos_nombre
          render json: { "status" => "FAIL", "msg" => "Todos los caballos deben tener nombre." }, status: 400 and return
        end
        caballos.each { |cab|
          buscar = CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab["id"])
          if buscar.present?
            buscar.update(nombre: cab["nombre"], retirado: cab["retirado"], jinete: cab['jinete'], entrenador: cab['entrenador'])
          else
            CaballosCarrera.create(carrera_id: carrera_id, numero_puesto: cab["id"], nombre: cab["nombre"], retirado: cab["retirado"], jinete: cab['jinete'], entrenador: cab['entrenador'],
                                   id_api: "#{Time.now.strftime('%Y%m%d')}-#{abreviacion}-#{carrera.numero_carrera}-#{cab["id"]}")
          end
        }
        update_redis_horas()
        ActionCable.server.broadcast "publicas_channel", { data: { "tipo" => 311 } }
        render json: { "status" => "OK" } and return
      else
        render json: { "status" => "FAIL", "msg" => "Debe ingresar caballos." }, status: 400 and return
      end
    # rescue Exception => e
    #   puts e.message
    #   render json: { "status" => "FAIL", "msg" => "Revise todos los datos." }, status: 400 and return
    # end
  end
end
