module Unica
  class ApiController < ApplicationController
    skip_before_action :verify_authenticity_token
    include ApplicationHelper
    SISTEMAS = ["https://admin-puesto.aposta2.com//unica/", 
                "https://adminrojonegro.betingxchange.com/unica/",
                "https://admin_tablas.betingxchange.com/unica/"]


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

    def cierre_carrera_interno
      hipodromo_id = params[:hipodromo_id]
      numero_carrera = params[:numero_carrera].to_i
      hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)
      unless hipodromo.present?
        render json: { "code" => -1, "msg" => "Hipodromo no existe." }, status: 400 and return
      end
      carr = hipodromo.jornada.where(fecha: Time.now.all_day).last.carrera.find_by(numero_carrera: numero_carrera)

      SISTEMAS.each do |sis_url|
        Thread.new { 
          sis_url = "#{sis_url}configuracion/cerrar_carrera"
          send_close_sistemas(sis_url, carr.id, carr.id_api)
        }
      end
    end

    def close_race
      CierreLog.create(parametros: params.to_json)
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      integrator = verificar_integrador(integrador_in, api_key_in)
      render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?
      numero_carrera = params[:race_number].to_i
      hipodromo = Hipodromo.find_by(abreviatura: params[:racecourse_track_id])
      render json: { 'code' => -1, 'msg' => 'Hipodromo no existe.' }, status: 400 and return unless hipodromo.present?
      bus_jornada = hipodromo.jornada.where(fecha: Time.now.all_day)
      unless bus_jornada.present?
        render json: { 'code' => -1, 'msg' => 'Jornada no creada para la fecha.' }, status: 400 and return
      end
      bus_carrera = bus_jornada.last.carrera.find_by(numero_carrera: numero_carrera)
      unless bus_carrera.present?
        render json: { 'code' => -1, 'msg' => "Carrera #{numero_carrera} no existe." }, status: 400 and return
      end
      render json: { 'code' => 1, 'msg' => 'Carrera cerrada con exito.' } and return unless hipodromo.cierre_api
      bus_carrera.update(activo: false)
      hipodromo_id = bus_carrera.jornada.hipodromo.id
      CierreCarrera.create(hipodromo_id: hipodromo_id, carrera_id: bus_carrera.id, user_id: 0)
      CierresApi.create(es_api: true, hipodromo_id: hipodromo.id, carrera_id: bus_carrera.id)
      SISTEMAS.each do |sis_url|
        Thread.new { 
          sis_url = "#{sis_url}configuracion/cerrar_carrera"
          send_close_sistemas(sis_url, bus_carrera.id, bus_carrera.id_api)
        }
      end
      render json: { status: 'OK', message: 'Data de cierre de carrera recibida.' }
    end

    def retirar_interno
      SISTEMAS.each do |sis_url|
        Thread.new { 
          uri = URI.parse("#{sis_url}retirados/retirar")
          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl = true
          req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
          req.body = { 'id' => params[:id], 'id_api' => params[:id_api], 'caballos' => params[:caballos], 'premia_api' => true, 'recibe_puestos' => true }.to_json
          https.request(req)
        }
      end
    rescue StandardError => e
      puts e
    end

    def verificar_retirado(data, numero_caballo)
      data.find { |ret| ret.to_s == numero_caballo.to_s }
    end

    def notify_scratches(hipodromo_id, numero_carrera, numero_caballo, status = 1)
      ActionCable.server.broadcast 'web_notifications_banca_channel', { data: { 'tipo' => 2501 } }
      retirar_pendiente(hipodromo_id, numero_carrera, numero_caballo, status)
    end

    def invalidate_horse
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      integrator = verificar_integrador(integrador_in, api_key_in)
      render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

      numero_carrera = params[:race_number].to_i
      numero_caballo = params[:horse_number]
      hipodromo = Hipodromo.find_by(abreviatura: params[:racecourse_track_id])

      render json: { 'code' => -1, 'msg' => 'Hipodromo no existe.' }, status: 400 and return unless hipodromo.present?

      bus_jornada = hipodromo.jornada.where(fecha: Time.now.all_day)
      unless bus_jornada.present?
        render json: { 'code' => -1, 'msg' => 'Jornada no creada para la fecha.' }, status: 400 and return
      end

      bus_carrera = bus_jornada.last.carrera.find_by(numero_carrera: numero_carrera)
      unless bus_carrera.present?
        render json: { 'code' => -1, 'msg' => "Carrera #{numero_carrera} no existe." }, status: 400 and return
      end

      buscar_caballo = bus_carrera.caballos_carrera.find_by(numero_puesto: numero_caballo)
      unless buscar_caballo.present?
        render json: { 'code' => -1, 'msg' => "Caballo con el numero #{numero_caballo} no existe." },
              status: 400 and return
      end
      return if PremiosIngresado.where(carrera_id: bus_carrera.id).present?

      caballos = [{"id"=> buscar_caballo.numero_puesto, "cab_id"=> buscar_caballo.id_api, "hid"=> hipodromo.id.to_s, "carr_id"=> bus_carrera.id.to_s, "retirado"=> true}]

      begin
        id_carrera_nyra = Hipodromos::Carreras.extrac_nyra_id_race(hipodromo, numero_carrera)
        scratches = Hipodromos::Carreras.results(bus_carrera.id, id_carrera_nyra)[1]

        unless verificar_retirado(scratches, numero_caballo).present?
          if params[:reintentar].present?
            notify_scratches(hipodromo_id, numero_carrera, numero_caballo, 9)
          else
            dos_minutos = Time.now + 2.minutes
            data_reenvio = { integrator_id: params[:integrator_id].to_i, api_key: params[:api_key],
                            racecourse_track_id: params[:racecourse_track_id],
                            race_number: params[:race_number].to_i, horse_number: params[:horse_number], reintentar: true }
            ReintentarRetirarCaballosApiJob.perform_at(dos_minutos, data_reenvio)
          end
          render json:
        else  
          SISTEMAS.each do |sis_url|
            Thread.new { 
              uri = URI.parse("#{sis_url}retirados/retirar")
              https = Net::HTTP.new(uri.host, uri.port)
              https.use_ssl = true
              req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
              req.body = { 'id' => bus_carrera.id, 'id_api' => bus_carrera.id_api, 'caballos' => caballos, 'premia_api' => true, 'recibe_puestos' => true }.to_json
              https.request(req)
            }
          end
        end
      rescue StandardError => e
        puts 'Error en nyra'
        puts e
      end

    end

    def retirar_pendiente(hip,carr,cab)
      begin
        buscar = CaballosRetiradosConfirmacion.where(hipodromo_id: hip, carrera_id: carr, caballos_carrera_id: cab)
        unless buscar.present?
          CaballosRetiradosConfirmacion.create(hipodromo_id: hip, carrera_id: carr, caballos_carrera_id: cab, status: 1 )
        end
      end
    end

    def activate_horse
      render json: { status: "OK"} and return 
    end

    def verificar_integrador(integrador_in, api_key_in)
      return Integrador.find_by(id: integrador_in, api_key: api_key_in, activo: true)
    end

    def post_time
      render json: { status: "OK"} and return 
    end

    def premiar_interno
    
      sistemas = ["https://admin-puesto.aposta2.com/unica/premiacion_puestos/premiar_puestos", 
                  "https://admin_tablas.betingxchange.com/unica/premiacion_tablas/premiar_tablas",
                  "https://adminrojonegro.betingxchange.com/unica/premiacion_rojonegro/premiar_rojonegro"]

      sistemas.each do |sis_url|
        Thread.new { 
          uri = URI.parse(sis_url)
          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl = true
          req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
          req.body = { 'id' => params[:carrera_id], 'id_api' => params[:id_api], 'caballos' => params[:caballos], 'premia_api' => true, 'recibe_puestos' => true }.to_json
          https.request(req)
        }
      end
    rescue StandardError => e
      puts e
    end

    def validate_nyra(resultados, carrera, codigo_nyra)
      res_api = resultados.map { |a| [a['horse_position'].to_s, a['horse_number']] }.sort
      id_carrera_nyra = Hipodromos::Carreras.carreras_por_hipodromo(codigo_nyra, carrera.numero_carrera)
      bus_nira = Hipodromos::Carreras.results(1, id_carrera_nyra)
      res_nyra = bus_nira['results'].sort
      retirados_nyra = bus_nira['scratches'].sort
      retirados_api = carrera.caballos_carrera.where(retirado: true).pluck(:numero_puesto).sort
      res_nyra.first(4) == res_api.first(4) and retirados_nyra == retirados_api
    rescue StandardError => e  
      return false
    end
    
    def award_race
      begin
        integrador_in = params[:integrator_id].to_i
        api_key_in = params[:api_key]
        integrator = verificar_integrador(integrador_in, api_key_in)
        unless integrator.present?
          render json: { "code" => -1, "msg" => "Integrador no valido." }, status: 400 and return
        end

        hipodromo_id = params[:racecourse_track_id]
        ids_jor = Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id)
        hipodromo = Hipodromo.where(id: ids_jor).find_by(id_goal: hipodromo_id, activo: true)
        resultados = params[:result].values
        numero_carrera = resultados.first['racecourse_race_number'].to_i
        unless hipodromo.present?
          render json: { "code" => 1, "msg" => "Resultados recibidos." } and return
        end
        CierreLog.create(parametros: params.to_json)

        bus_jornada = hipodromo.jornada.where(fecha: Time.now.all_day)
        unless bus_jornada.present?
          render json: { "code" => 1, "msg" => "Resultados recibidos." } and return
        end
        bus_carrera = bus_jornada.last.carrera.find_by(numero_carrera: numero_carrera)
        unless bus_carrera.present?
          render json: { "code" => 1, "msg" => "Resultados recibidos." } and return
        end
        buscar_caballos = bus_carrera.caballos_carrera
        datos = []
        resultados.each { |res|
          datos << { "id" => buscar_caballos.find_by(numero_puesto: res["horse_number"]).id, "puesto" => res["horse_number"], "llegada" => res["horse_position"], "retirado" => false }
        }

        buscar_caballos.where.not(id: datos.map { |d| d["id"] }).each do |cab|
            datos << { "id" => cab.id, "puesto" => cab.numero_puesto, "llegada" => 0, "retirado" => cab.retirado }
        end
        enviar = { "id" => bus_carrera.id, "caballos" => datos, "fecha" => Time.now.strftime("%Y-%m-%d"), "premia_api" => true }
        busca_antes = PremiosIngresado.find_by(hipodromo_id: hipodromo.id, carrera_id: bus_carrera.id)
        unless busca_antes.present?
          PremioasIngresadosApi.create(hipodromo_id: hipodromo.id, carrera_id: bus_carrera.id, resultado: datos.to_json)
        end
        if validate_nyra(resultados, bus_carrera, hipodromo.codigo_nyra)
          sistemas = ["https://admin-puesto.aposta2.com/unica/premiacion_puestos/premiar_puestos", 
                      "https://admin_tablas.betingxchange.com/unica/premiacion_tablas/premiar_tablas",
                      "https://adminrojonegro.betingxchange.com/unica/premiacion_rojonegro/premiar_rojonegro"]
    
          sistemas.each do |sis_url|
            Thread.new { 
              uri = URI.parse(sis_url)
              https = Net::HTTP.new(uri.host, uri.port)
              https.use_ssl = true
              req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
              req.body = { 'id' => bus_carrera.id, 'id_api' => bus_carrera.id_api, 'caballos' => datos, 'premia_api' => true, 'recibe_puestos' => true }.to_json
              https.request(req)
            }
          end
        end

        render json: { "code" => 1, "msg" => "Resultados recibidos." }
      rescue
        render json: { "code" => -1, "msg" => "Algo salio mal, revise los parametros." }, status: 400
      end
    end

    def validar_json(json)
      JSON.parse(json)
    rescue JSON::ParserError => e
      false
    end


  end
end