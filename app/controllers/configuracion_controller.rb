class ConfiguracionController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_user_auth, only: [:posttime, :masivo]

  before_action :seguridad_cuentas, only: [:masivo, :posttime, :reglas]
  include ApiHelper

  def masivo
    bloqueo = BloqueoMasivo.last
    if bloqueo.present?
      @activo = bloqueo.activo
    else
      BloqueoMasivo.create(activo: false)
      @activo = false
    end
    render action: "masivo"
  end

  def bloqueo_masivo
    activo = params[:activo]
    bmasivo = BloqueoMasivo.last
    bmasivo.update(activo: activo)
    if bmasivo.activo
      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "BLOQUEO_MASIVO" } }
    end
    render json: { "status" => "OK" }
  end

  def posttime
    ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
    @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime("%H:%M")}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(10)
    @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).order(:nombre_largo)
    horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
    REDIS.set("cierre_carre", horas_carrera.to_json)
    REDIS.close
    horas_min = []
    horas_carrera.each { |hc|
      if hc[1] != ""
        horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    }
    ActionCable.server.broadcast "publicas_channel", { data: { "tipo" => 1, "hora" => horas_min } }
    @mintos_restantes = horas_min.to_json
  end

  def buscar_carrera
    carreras = Carrera.where(jornada_id: params[:id].to_i, activo: true).order(:id, :numero_carrera)
    if carreras.present?
      render json: { "carreras" => carreras }
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def buscar_carrera2
    carrera = Carrera.find_by(id: params[:id])
    if carrera.hora_carrera.present?
      render json: { "status" => "OK", "hora" => carrera.hora_carrera[0, 5] }
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def cambiar_hora
    carrera = Carrera.find_by(id: params[:id])
    if carrera.hora_carrera.present?
      if carrera.hora_carrera < params[:hora]
        Postime.create(user_id: session[:usuario_actual]["id"], hora_anterior: carrera.hora_carrera, nueva_hora: params[:hora], carrera_id: params[:id])
        carrera.update(hora_carrera: params[:hora])
        ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
        @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime("%H:%M")}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(10)

        horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
        REDIS.set("cierre_carre", horas_carrera.to_json)
        REDIS.close
        horas_min = []
        horas_carrera.each { |hc|
          if hc[1] != ""
            horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
          end
        }
        ActionCable.server.broadcast "publicas_channel", { data: { "tipo" => 1, "hora" => horas_min } }
        @mintos_restantes = horas_min.to_json

        render partial: "proximas", layout: false
      else
        render json: { "status" => "FAILD" }, status: 400
      end
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def cerrar_carrera
    carrera_id = params[:id].to_i
    carrera = Carrera.find_by(id: carrera_id)
    if carrera.present?
      carrera.update(activo: false)
      hipodromo_id = carrera.jornada.hipodromo.id
      CierreCarrera.create(hipodromo_id: hipodromo_id, carrera_id: params[:id].to_i, user_id: session[:usuario_actual]["id"])
      propuestas = Propuesta.where(carrera_id: carrera_id, activa: true, created_at: Time.now.all_day)
      CerrarCarreraApiJob.perform_async propuestas.pluck(:id), hipodromo_id, carrera_id
      if propuestas.present?
        updates = propuestas.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
        # propuestas.each { |prop|
        #   OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: "Reverso por carrera cerrada prop: #{prop.id}", monto: prop.monto, status: 0, moneda: prop.moneda)
        # }
      end

      begin
        require "net/http"
        uri = URI("http://127.0.0.1:3003/notificaciones/cerrar_carrera")
        res = Net::HTTP.post_form(uri, "carrera_id" => carrera_id)
      rescue Exception => e
        puts e.message
      end
      ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime("%H:%M")}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(10)
      horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
      REDIS.set("cierre_carre", horas_carrera.to_json)
      REDIS.close
      horas_min = []
      horas_carrera.each { |hc|
        if hc[1] != ""
          horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
        end
      }
      @mintos_restantes = horas_min.to_json
      render partial: "proximas", layout: false
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def reglas
    reglas = Regla.last
    unless reglas.present?
      @reglas = ""
    else
      @reglas = reglas.texto
    end
  end

  def grabar_reglas
    reglas = Regla.last
    unless reglas.present?
      Regla.create(texto: params[:texto])
    else
      reglas.update(texto: params[:texto])
    end
  end
end
