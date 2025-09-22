class RetiradosController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :seguridad_cuentas, only: [:index]

  def show
    @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).order(:nombre)
    render action: "index"
  end

  def crear_caballos
    carrera_id = params[:id].to_i
    cantidad = params[:cantidad].to_i
    caballos = CaballosCarrera.where(carrera_id: params[:id]).order(:id)
    @caballos_array = []
    cantidad_total = 0
    @esupdate = false
    if caballos.present?
      @esupdate = true
      caballos.each { |ca|
        @caballos_array << { "numero_puesto" => ca.numero_puesto, "nombre" => ca.nombre, "retirado" => ca.retirado }
        cantidad_total = ca.numero_puesto
      }
    else
      render json: { "status" => "FAILD" }, status: 400
    end
    render partial: "retirados/caballos", layout: false
  end

  def buscar_carreras
    cantidad_carreras = Carrera.where(activo: true, jornada_id: params[:id].to_i, id: CaballosCarrera.where(carrera_id: Carrera.where(jornada_id: params[:id].to_i).pluck(:id)).pluck(:carrera_id)).order(:id).pluck(:numero_carrera)
    carreras = Carrera.where(activo: true, jornada_id: params[:id].to_i).order(:id)
    premios = PremiosIngresado.where(jornada_id: params[:id].to_i).to_a
    carreras = carreras.each { |car|
      bus = premios.select { |item| item["carrera_id"].to_i == car.id }
      if bus.present?
        car.numero_carrera = car.numero_carrera + " Premiada"
      end
    }
    if carreras.present?
      render json: { "carreras" => carreras, "cantidad_carreras" => cantidad_carreras }
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def retirar
    carrera_id = params[:id]
    caballos = params[:caballos]
    todos_caballos_nombre = true
    arreglo_enjuego = []
    arreglo_propuestas = []
    hipodromo = Carrera.find(carrera_id).jornada.hipodromo
    cantidad_caballos = CaballosCarrera.where(carrera_id: Carrera.find(carrera_id).id).count - caballos.select { |cab| cab["retirado"] == true }.count
    retirar_tipo = []
    retirados_propuestas = []
    retirados_enjuego = []
    ####################
    case cantidad_caballos
    when 5
      retirar_tipo = [15, 16, 17]
    when 4
      retirar_tipo = [11, 12, 13, 14, 15, 16, 17]
    when 3
      retirar_tipo = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    when 2
      retirar_tipo = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    end
    carr = Carrera.find(carrera_id)
    begin
      if caballos.count > 0
        caballos.each { |cab|
          buscar = CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab["id"])
          #,retirado: false)
          if buscar.present?
            if cab["retirado"] and buscar.retirado == false
              buscar.update(retirado: true)
              bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo.id, carrera_id: carr.id, caballos_carrera_id: buscar.id)
              if bus_cab_ret_api.present?
                bus_cab_ret_api.update(status: 2, user_id: session[:usuario_actual]["id"])
              end
              ActionCable.server.broadcast "web_notifications_banca_channel", { data: { "tipo" => 2502, "cab_id" => buscar.id }}
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
                  retirados_propuestas << enj.propuesta_id
                  retirados_enjuego << enj.id

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
                    retirados_propuestas << enj.propuesta_id
                    retirados_enjuego << enj.id

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
                  retirados_propuestas << prop.id
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
                    retirados_propuestas << prop.id
                    # OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Devolucion/Retirado: #{Carrera.find(carrera_id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
                  }
                end
              end
            else
              if cab["retirado"] == false and buscar.retirado
                buscar.update(retirado: false)
              end
            end
          end
        }
        unless params[:es_interno].present?
          render json: { "status" => "OK" }
        end
        ActionCable.server.broadcast("publicas_channel", { data: { "tipo" => 8888, "carrera" => carrera_id.to_i }})
        if retirados_propuestas.length > 0 or retirados_enjuego.length > 0
          RetirarCaballosApiJob.perform_async [retirados_propuestas, retirados_enjuego], hipodromo.id, carr.id
        end
      else
        unless params[:es_interno].present?
          render json: { "status" => "FAIL", "msg" => "No hay caballos para esta carrera." }, status: 400 and return
        end
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      unless params[:es_interno].present?
        render json: { "status" => "FAIL", "msg" => "Revise todos los datos." }, status: 400 and return
      end
    end
  end

  def respáldo_filtrar_por_hipodromo_interno(carrera, cabid, moneda, puesto)
    hora_carrera = Carrera.find(carrera).hora_carrera
    cab = CaballosCarrera.find(cabid)
    @caballos = []
    juegan = []
    juegan2 = []
    juegan3 = []
    juegan4 = []
    juegan5 = []
    juegan6 = []
    juegan51 = []
    juegan61 = []

    horas_carrera = JSON.parse(REDIS.get("cierre_carre"))
    REDIS.close
    horas_min = []
    horas_carrera.each { |hc|
      if hc[1] != ""
        horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    }

    colores_celda = color_celda_caballo()[puesto.to_i.to_s]
    @caballos << { "id" => cab.id, "colores_celda" => colores_celda, "puesto" => cab.numero_puesto, "caballo" => cab.nombre.gsub("'", "\`").gsub("'", "."), "jugadas_bs" => juegan.last(3), "jugadas_usd" => juegan2.last(3), "banqueadas_bs" => juegan3, "banqueadas_usd" => juegan4, "enjuego_bs" => juegan5, "enjuego_usd" => juegan6, "retirado" => cab.retirado, "minutos_resta" => horas_min, "moneda" => moneda }
    return @caballos
  end

  def color_celda_caballo
    {
      "1" => { "fondo" => "#ff1100", "letra" => "#ffffff" },
      "2" => { "fondo" => "#fcfdfc", "letra" => "#000000" },
      "3" => { "fondo" => "#2659c2", "letra" => "#ffffff" },
      "4" => { "fondo" => "#f7eb00", "letra" => "#000000" },
      "5" => { "fondo" => "#00aa4f", "letra" => "#ffffff" },
      "6" => { "fondo" => "#35373a", "letra" => "#f7eb00" },
      "7" => { "fondo" => "#f47e37", "letra" => "#000000" },
      "8" => { "fondo" => "#f8b6c3", "letra" => "#000000" },
      "9" => { "fondo" => "#00b5af", "letra" => "#000000" },
      "10" => { "fondo" => "#6510b3", "letra" => "#ffffff" },
      "11" => { "fondo" => "#7c8180", "letra" => "#ff1100" },
      "12" => { "fondo" => "#82c341", "letra" => "#333333" },
      "13" => { "fondo" => "#5c2913", "letra" => "#ffffff" },
      "14" => { "fondo" => "#760c30", "letra" => "#f7eb00" },
      "15" => { "fondo" => "#b4a87d", "letra" => "#333333" },
      "16" => { "fondo" => "#2b547e", "letra" => "#fff" },
      "17" => { "fondo" => "navy", "letra" => "#fff" },
      "18" => { "fondo" => "#4e9258", "letra" => "#fff" },
      "19" => { "fondo" => "#c2dfff", "letra" => "#000" },
      "20" => { "fondo" => "#e4287c", "letra" => "#fff" },
      "21" => { "fondo" => "#e4287c", "letra" => "#fff" },
      "22" => { "fondo" => "#e4287c", "letra" => "#fff" },
      "23" => { "fondo" => "#e4287c", "letra" => "#fff" },
      "24" => { "fondo" => "#e4287c", "letra" => "#fff" },
      "25" => { "fondo" => "#e4287c", "letra" => "#fff" },
    }
  end

  def retirar_pendientes
    begin
      ActiveRecord::Base.transaction do
        datos = params[:data]
        datos.each { |dat|
          CaballosRetiradosConfirmacion.find_by(hipodromo_id: dat["hid"], carrera_id: dat["carr_id"], caballos_carrera_id: dat["cab_id"]).update(status: 2, user_id: session[:usuario_actual]["id"])
        }
        datos_agrupados = datos.group_by { |d| d["carr_id"] }
        datos_agrupados.each { |dat, value|
          params[:id] = dat
          params[:caballos] = value
          params[:es_interno] = true
          retirar()
        }
        render json: { "status" => "OK" }
      end
    rescue
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  private

  def actualizar_saldos(usuario_id, descripcion, monto, moneda)
    # OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: moneda)
  end
end
