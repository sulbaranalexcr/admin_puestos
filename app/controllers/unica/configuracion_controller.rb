module Unica

  class ConfiguracionController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :check_user_auth, only: [:posttime, :masivo, :montos_propuestas, :grabar_montos_propuestas]

    before_action :seguridad_cuentas, only: [:masivo, :posttime, :reglas, :montos_propuestas, :grabar_montos_propuestas]
    include ApiHelper

    def montos_propuestas_deportes
      deportes = Juego.where(juego_id: Liga.where(activo: true).pluck(:juego_id)).order(:nombre)
      tipos = { 1 => 'Money Line', 2 => 'Run Line', 3 => 'Alta y Baja' }
      tmp_data = []
      deportes.each do |dep|
        tipos.each do |tipo|
          tmp_data << { deporte_id: dep.juego_id, nombre: dep.nombre, tipo: tipo[0], tipo_nombre: tipo[1], monto: 0 }
        end
      end
      data = MontosGeneradorPropuesta.last
      if data.present?
        tmp_data.each do |tmp|
          monto_in = data.data.find { |a| a['deporte_id'].to_i == tmp[:deporte_id].to_i && a['tipo'].to_i == tmp[:tipo].to_i }
          tmp[:monto] = monto_in['monto'] if monto_in.present?
        end
      end
      @deportes = tmp_data
    end

    def grabar_montos_propuestas_deportes
      bus = MontosGeneradorPropuesta.last
      if bus.present?
        bus.update(data: JSON.parse(params[:datos]))
      else
        MontosGeneradorPropuesta.create(data: JSON.parse(params[:datos]))
      end
    end

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
        ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "BLOQUEO_MASIVO"}}
      end
      render json: { "status" => "OK" }
    end

    def cierre_manual
      ids_hip = Hipodromo.where( activo: true).ids
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      @hipodromos = Hipodromo.where( activo: true).order(:nombre_largo)
    end

    def posttime
      ids_hip = Hipodromo.where(activo: true).ids
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      @hipodromos = Hipodromo.where( activo: true).order(:nombre_largo)
      @sin_premiar = Carrera.where("hora_carrera < '#{Time.now.strftime('%H:%M')}'")
                            .where(jornada_id: Jornada
                            .where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids)
                            .where.not('id in (select carrera_id from premios_ingresados where carrera_id = carreras.id)')
                            .order(:hora_carrera)
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

    def update_hour_order(hip_id)
      carreras = Hipodromo.find(hip_id).jornada.last.carrera.where(activo: true).order(:id)
      first_hour = ''
      carreras.each_with_index do |carrera, index|
        next if index.zero?

        first_hour = carreras[index - 1].hora_carrera.to_time + 10.minutes
        change_to_new_hour(carrera, first_hour)
      end
    end

    def change_to_new_hour(carrera, first_hour)
      carrera.update(hora_carrera: first_hour.strftime('%H:%M')) if first_hour > carrera.hora_carrera.to_time
    end

    def cambiar_hora
      carrera = Carrera.find_by(id: params[:id])
      if carrera.hora_carrera.present?
        if carrera.hora_carrera < params[:hora]
          Postime.create(user_id: session[:usuario_actual]["id"], hora_anterior: carrera.hora_carrera, nueva_hora: params[:hora], carrera_id: params[:id])
          carrera.update(hora_carrera: params[:hora])
          hip_id = carrera.jornada.hipodromo.id
          update_hour_order(hip_id)

          ids_hip = Hipodromo.where( activo: true).ids
          @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime("%H:%M")}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)

          horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
          REDIS.set("cierre_carre", horas_carrera.to_json)
          REDIS.close
          horas_min = []
          horas_carrera.each { |hc|
            if hc[1] != ""
              horas_min << { "id" => hc[0], "resta" => ((hc[1].to_time - Time.now.to_time) / 60).round(1), "resta_taq" => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
            end
          }
          ActionCable.server.broadcast "publicas_channel", { data: { "tipo" => 1, "hora" => horas_min }}
          @mintos_restantes = horas_min.to_json

          render partial: "proximas", layout: false and return unless params[:tipo].present?


          carreras_enviar = Hipodromo.find(hip_id).jornada.last.carrera.where(activo: true).order(:id)
          render json: { carreras: carreras_enviar }
        else
          render json: { "status" => "FAILD" }, status: 400
        end
      else
        render json: { "status" => "FAILD" }, status: 400
      end
    end

    def send_close_sistemas(url, carrera_id, id_api)
      uri = URI.parse(url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
      req.body = { 'id' => carrera_id, 'recibe_puestos' => true, 'id_api' => id_api}.to_json
      https.request(req)
    rescue StandardError => e
      puts e
    end

    def send_to_api(carrera_id, id_api, hipodrmo_id, numero_carrera)
      uri = URI.parse('https://admin-puesto.aposta2.com/api/cierre_carrera_interno')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
      req.body = { 'id' => carrera_id, 'id_api' => id_api, 'hipodromo_id' => hipodrmo_id, 'numero_carrera' => numero_carrera }.to_json
      https.request(req)
    rescue StandardError => e
      puts e
    end

    def cerrar_carrera_manual
      carrera = Carrera.find(params[:id].to_i)
      ActionCable.server.broadcast 'web_notifications_banca_channel', { data: { 'tipo' => 'REFRESH_POR_TIPO', "id" => params[:id].to_s } }
      send_to_api(carrera.id, carrera.id_api, carrera.jornada.hipodromo.abreviatura, carrera.numero_carrera)
      render json: { status: 'OK'}
    end

    def cerrar_carrera
      carrera = if params[:recibe_puestos].present?
                         Carrera.find_by(id_api: params[:id_api])
                       else
                         Carrera.find(params[:id].to_i)
                       end
      return unless carrera.present?                 
      
      carrera_id = carrera.id
      usuario_premia = params[:recibe_puestos].present? ? User.first.id : session[:usuario_actual]['id']

      # Thread.new {
      ActionCable.server.broadcast 'web_notifications_banca_channel', { data: { 'tipo' => 'REFRESH_POR_TIPO', "id" => carrera_id.to_s } }
      ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS', "id" => carrera_id.to_i } }
      Servicios::Carreras.new.cerrar(carrera_id.to_i, usuario_premia)
      RacerService::Racer.new.close_racer(carrera.jornada.hipodromo_id, carrera.id)
      # }
      
      # sistemas = ["https://admin.unpuestos.com/unica/configuracion/cerrar_carrera",
      #             "https://admin.tablasdinamica.com/unica/configuracion/cerrar_carrera",
      #             "https://admin.rojosynegros.com/unica/configuracion/cerrar_carrera",
      #             "https://admin.piramidehipica.com/unica/configuracion/cerrar_carrera"]

      # if ENV['reenvia_apis'] == 'SI'
      #   unless params[:recibe_puestos].present?
      #     sistemas.each do |sis_url|
      #       Thread.new { 
      #         send_close_sistemas(sis_url, carrera.id, carrera.id_api)
      #       }
      #     end
      #   end
      # end

      ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
      REDIS.set('cierre_carre', horas_carrera.to_json)
      REDIS.close
      horas_min = []
      horas_carrera.each do |hc|
        if hc[1] != ''
          horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1), 'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
        end
      end
      @mintos_restantes = horas_min.to_json
      ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).order(:nombre_largo)
      @sin_premiar = Carrera.where("hora_carrera < '#{Time.now.strftime('%H:%M')}'")
                            .where(jornada_id: Jornada
                            .where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids)
                            .where.not('id in (select carrera_id from premios_ingresados where carrera_id = carreras.id)')
                            .order(:hora_carrera)

      render partial: 'selectores', layout: false
      # carrera_id = params[:id].to_i
      # ActiveRecord::Base.connection.execute("update carreras set updated_at = now(), activo = false where id = #{carrera_id}")
      # carrera = Carrera.find_by(id: carrera_id)
      # hipodrmo_id = carrera.jornada.hipodromo_id
      # ActionCable.server.broadcast 'publicas_deporte_channel', data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS', "id" => carrera_id.to_i }
      # ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
      # @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      # redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      # horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id, :hora_carrera, :hora_pautada)
      # redis.set('cierre_carre', horas_carrera.to_json)
      # horas_min = []
      # horas_carrera.each { |hc|
      #   if hc[1] != ''
      #     horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1), 'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      #   end
      # }
      # @mintos_restantes = horas_min.to_json
      # ids_hip = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).ids
      # @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(jornada_id: Jornada.where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids, activo: true).order(:hora_carrera).limit(20)
      # @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true).order(:nombre_largo)
      # @sin_premiar = Carrera.where("hora_carrera < '#{Time.now.strftime('%H:%M')}'")
      #                       .where(jornada_id: Jornada
      #                       .where(hipodromo_id: ids_hip, fecha: Time.now.all_day).ids)
      #                       .where.not('id in (select carrera_id from premios_ingresados where carrera_id = carreras.id)')
      #                       .order(:hora_carrera)

      # render partial: 'selectores', layout: false
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

    def cuadrar_carrera
      carrera_id = params[:id]
      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "CUADRAR_CARRERA_CABALLOS", "id" => carrera_id.to_i }}
    end

  end
end
