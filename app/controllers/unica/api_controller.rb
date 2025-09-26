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
      render json: { status: "OK"} and return 

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
      render json: { status: "OK"} and return 
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
          render json: { 'codigo' => -8899, 'msg' => 'Caballo a retirar no coinciden' }
          return
        end
      rescue StandardError => e
        puts 'Error en nyra'
        puts e
      end

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
    
      sistemas = ["https://admin-puesto.aposta2..com/unica/premiacion_puestos/premiar_puestos", 
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
      render json: { status: "OK"} and return 
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
        numero_carrera = params[:race_number].to_i
        resultados = params[:result]

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
          sistemas = ["https://admin.betsolutiongroup.com/unica/premiacion_puestos/premiar_puestos", 
                      "https://admin.betsolutionsgroup.com/unica/premiacion_puestos/premiar_puestos",
                      "https://admintablas.gamehorses.com/unica/premiacion_tablas/premiar_tablas",
                      "https://admin.tablasdinamica.com/unica/premiacion_tablas/premiar_tablas",
                      "https://adminrojonegro.gamehorses.com/unica/premiacion_rojonegro/premiar_rojonegro", 
                      "https://admin.rojosynegros.com/unica/premiacion_rojonegro/premiar_rojonegro"]
    
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

    def get_currencys
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      integrator = verificar_integrador(integrador_in, api_key_in)
      if integrator.present?
        monedas_disponibles = FactorCambio.where(grupo_id: integrator.grupo_id).pluck(:moneda_id)
        unless monedas_disponibles.present?
          render json: { "code" => -2, "msg" => "No hay monedas configurada.", "status" => 400 }, status: 400 and return
        end
        monedas = Moneda.where(id: monedas_disponibles)
        datos = []
        monedas.each { |mon|
          factor = FactorCambio.find_by(grupo_id: integrator.grupo_id, moneda_id: mon.id)
          datos << { "id" => mon.id, "country" => mon.pais, "abbreviation" => mon.abreviatura, "exchange_rate" => factor.valor_dolar }
        }
        render json: { "code" => 1, "msg" => "Transaccion completada.", "currencys" => datos, "status" => 200 }
      else
        render json: { "code" => -1, "msg" => "integrador no valido", "status" => 400 }, status: 400 and return
      end
    end

    def update_exchange_rate
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      ip_integrador = request.remote_ip
      integrator = verificar_integrador(integrador_in, api_key_in)
      moneda_entrante = params[:currency_id].to_i
      monto_entrada = params[:exchange_rate].to_f

      if integrator.present?
        obtenet_data = request.location.data()
        moneda_disponible = FactorCambio.find_by(grupo_id: integrator.grupo_id, moneda_id: moneda_entrante)
        unless moneda_disponible.present?
          render json: { "code" => -3, "msg" => "Moneda no configurada.", "status" => 400 }, status: 400 and return
        end
        moneda = Moneda.find(moneda_entrante)
        monto_antrior = moneda_disponible.valor_dolar.to_f.round(2)
        moneda_disponible.update(valor_dolar: monto_entrada)
        HistorialTasa.create(user_id: User.where(grupo_id: integrator.grupo_id).last.id, moneda_id: moneda_entrante, tasa_anterior: monto_antrior.to_f.round(2), tasa_nueva: monto_entrada, ip_remota: request.remote_ip, grupo_id: integrator.grupo_id, geo: obtenet_data.to_json)
        datos = { "id" => moneda.id, "country" => moneda.pais, "abbreviation" => moneda.abreviatura, "exchange_rate_previous" => monto_antrior, "exchange_rate_current" => moneda_disponible.valor_dolar.to_f.round(2) }
        render json: { "code" => 2, "msg" => "Transaccion completada.", "currency" => datos, "status" => 200 }
      else
        render json: { "code" => -1, "msg" => "integrador no valido", "status" => 400 }, status: 400 and return
      end
    end

    def get_currency_interno(grupo_id, id)
      monedas = Moneda.find_by(id: id)
      factor = FactorCambio.find_by(grupo_id: grupo_id, moneda_id: id)
      if factor.present?
        return [monedas.abreviatura, factor.valor_dolar.to_f]
      else
        return []
      end
    end


    def set_max_min
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      integrator = verificar_integrador(integrador_in, api_key_in)
      minimo = params[:min].to_f
      maximo = params[:max].to_f
      if integrator.present?
        UsuariosTaquilla.where(integrador_id: integrador_in).update(jugada_minima_usd: minimo, jugada_maxima_usd: maximo)
        render json: { "code" => 1, "msg" => "Transaccion completada.", "status" => 200 } and return
      else
        render json: { "code" => -1, "msg" => "integrador no valido", "status" => 400 }, status: 400 and return
      end


    end

    def get_config
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      moneda_entrante = params[:currency_id].to_i
      internal_id = params[:user_id].to_i
      integrator = verificar_integrador(integrador_in, api_key_in)
      if integrator.present?
        user = UsuariosTaquilla.find_by(id: internal_id)
        if user.present?
          if moneda_entrante != 2
            consulta_moneda = get_currency_interno(integrator.grupo_id, moneda_entrante)
            if consulta_moneda.length == 0
              render json: { "code" => -4, "msg" => "Moneda no configurada para tipo de cambio.", "status" => 400 }, status: 400 and return
            end
            datos = {
              "id" => user.id,
              "name" => user.nombre,
              "alias" => user.alias,
              "email" => user.correo,
              "proposes" => user.propone,
              "take" => user.toma,
              "commission" => user.comision.to_f,
              "active" => user.activo,
              "limits" => {
                "usd" => {
                  "min_bet_usd" => user.jugada_minima_usd,
                  "max_bet_usd" => user.jugada_maxima_usd,
                },
                "requested_currency" => {
                  "min_bet" => (user.jugada_minima_usd * consulta_moneda[1].to_f),
                  "max_bet" => (user.jugada_maxima_usd * consulta_moneda[1].to_f),
                  "requested_currency" => consulta_moneda[0],
                  "exchange_rate" => consulta_moneda[1],
                },
              },
            }

            render json: { "code" => 10, "msg" => "Transaccion completada.", "data" => datos, "status" => 200 } and return
          else
            datos = {
              "id" => user.id,
              "name" => user.nombre,
              "alias" => user.alias,
              "email" => user.correo,
              "proposes" => user.propone,
              "take" => user.toma,
              "commission" => user.comision.to_f,
              "active" => user.activo,
              "limits" => {
                "usd" => {
                  "min_bet_usd" => user.jugada_minima_usd,
                  "max_bet_usd" => user.jugada_maxima_usd,
                },
                "requested_currency" => {
                  "min_bet" => user.jugada_minima_usd,
                  "max_bet" => user.jugada_maxima_usd,
                  "requested_currency" => "USD",
                  "exchange_rate" => 1,
                },
              },
            }

            render json: { "code" => 10, "msg" => "Transaccion completada.", "data" => datos, "status" => 200 } and return
          end
        else
          render json: { "code" => -2, "msg" => "Error al validar usuario, verifique los datos", "status" => 400 }, status: 400 and return
        end
      else
        render json: { "code" => -1, "msg" => "integrador no valido", "status" => 400 }, status: 400 and return
      end
    end

    def set_config
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      moneda_entrante = params[:currency_id].to_i
      internal_id = params[:user_id].to_i
      integrator = verificar_integrador(integrador_in, api_key_in)
      propone = params[:proposes]
      toma = params[:take]
      comision = params[:commission].to_f
      activo = params[:active]
      juada_minima = params[:min_bet].to_f
      juada_maxima = params[:max_bet].to_f
      minima_convertida = 0
      maxima_convertida = 0
      if integrator.present?
        user = UsuariosTaquilla.find_by(id: internal_id)
        if user.present?
          if moneda_entrante != 2
            consulta_moneda = get_currency_interno(integrator.grupo_id, moneda_entrante)
            if consulta_moneda.length == 0
              render json: { "code" => -4, "msg" => "Moneda no configurada para tipo de cambio.", "status" => 400 }, status: 400 and return
            end
            maxima_convertida = (juada_maxima / consulta_moneda[1].to_f).round(3)
            minima_convertida = (juada_minima / consulta_moneda[1].to_f).round(3)
            unless propone.present?
              propone = user.propone
            end
            unless toma.present?
              toma = user.toma
            end
            unless comision.present?
              comision = user.comision
            end
            unless activo.present?
              activo = user.activo
            end

            user.update(propone: propone, toma: toma, comision: comision, activo: activo, jugada_minima_usd: minima_convertida, jugada_maxima_usd: maxima_convertida)
            datos = {
              "id" => user.id,
              "name" => user.nombre,
              "alias" => user.alias,
              "email" => user.correo,
              "proposes" => user.propone,
              "take" => user.toma,
              "commission" => user.comision.to_f,
              "active" => user.activo,
              "limits" => {
                "usd" => {
                  "min_bet_usd" => user.jugada_minima_usd,
                  "max_bet_usd" => user.jugada_maxima_usd,
                },
                "requested_currency" => {
                  "min_bet" => (user.jugada_minima_usd * consulta_moneda[1].to_f),
                  "max_bet" => (user.jugada_maxima_usd * consulta_moneda[1].to_f),
                  "requested_currency" => consulta_moneda[0],
                  "exchange_rate" => consulta_moneda[1],
                },
              },
            }

            render json: { "code" => 10, "msg" => "Transaccion completada.", "data" => datos, "status" => 200 } and return
          else
            user.update(propone: propone, toma: toma, comision: comision, activo: activo, jugada_minima_usd: juada_minima.round(3), jugada_maxima_usd: juada_maxima.round(3))
            datos = {
              "id" => user.id,
              "name" => user.nombre,
              "alias" => user.alias,
              "email" => user.correo,
              "proposes" => user.propone,
              "take" => user.toma,
              "commission" => user.comision.to_f,
              "active" => user.activo,
              "limits" => {
                "usd" => {
                  "min_bet_usd" => user.jugada_minima_usd,
                  "max_bet_usd" => user.jugada_maxima_usd,
                },
                "requested_currency" => {
                  "min_bet" => user.jugada_minima_usd,
                  "max_bet" => user.jugada_maxima_usd,
                  "requested_currency" => "USD",
                  "exchange_rate" => 1,
                },
              },
            }

            render json: { "code" => 10, "msg" => "Transaccion completada.", "data" => datos, "status" => 200 } and return
          end
        else
          render json: { "code" => -2, "msg" => "Error al validar usuario, verifique los datos", "status" => 400 }, status: 400 and return
        end
      else
        render json: { "code" => -1, "msg" => "integrador no valido", "status" => 400 }, status: 400 and return
      end
    end

    def retirar_ejemplar(hip_id, carrera_id, caballo)
      caballos = [caballo]
      todos_caballos_nombre = true
      arreglo_enjuego = []
      arreglo_propuestas = []
      retirados_propuestas = []
      retirados_enjuego = []
      hipodromo = Hipodromo.find_by(abreviatura: hip_id)
      carrera_bus = Hipodromo.find_by(abreviatura: hip_id).jornada.last.carrera.find_by(numero_carrera: carrera_id)
      cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_bus.id, retirado: false).count - 1
      retirar_tipo = []
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
      carr = carrera_bus
      begin
        if caballos.count > 0
          caballos.each { |cab|
            buscar = CaballosCarrera.find_by(carrera_id: carr.id, numero_puesto: cab, retirado: false)
            if buscar.present?
                buscar.update(retirado: true)
                if cab["retirado"] and buscar.retirado == false
                  buscar.update(retirado: true)
                  bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo.id, carrera_id: carr.id, caballos_carrera_id: buscar.id)
                  if bus_cab_ret_api.present?
                    bus_cab_ret_api.update(status: 2, user_id: session[:usuario_actual]["id"])
                  end
                  #ActionCable.server.broadcast "publicas_deporte_channel", data: { "tipo" => "RETIRAR_CABALLOS", "id" => buscar.id.to_i }
                  enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: buscar.id, status: [1, 2])
                  if enjuego.present?
                    enjuego.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
                    enjuego.each { |enj|
                      if enj.status == 1
                        OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                        busca_user = buscar_cliente_cajero(enj.id_propone)
                        if busca_user != "0"
                          if enj.id_propone == enj.id_juega
                            tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                            reference_id_propone = enj.reference_id_juega
                          else
                            tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                            reference_id_propone = enj.reference_id_banquea
                          end
                          set_envios_api(3, busca_user, tickets_detalle_id_propone, reference_id_propone, enj.monto.to_f, "Devolucion/Retirado")
                        end
                      else
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.id_juega == enj.id_propone
                          monto_banqueado = enj.cuanto_gana_completo.to_f
                          cuanto_juega = enj.monto.to_f
                        else
                          monto_banqueado = enj.monto.to_f
                          cuanto_juega = enj.cuanto_gana_completo.to_f
                        end
                        retirados_propuestas << enj.id
                        retirados_enjuego << enj.id
                        OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                        OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                        busca_user = buscar_cliente_cajero(id_quien_juega)
                        if busca_user != "0"
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_juega.to_f, "Devolucion/Retirado")
                        end
                        busca_user = buscar_cliente_cajero(id_quien_banquea)
                        if busca_user != "0"
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, monto_banqueado.to_f, "Devolucion/Retirado")
                        end
                      end
                    }
                  end
                  if retirar_tipo.length > 0
                    enjuego = PropuestasCaballosPuesto.where(carrera_id: carrera_id, activa: false, status: 2, tipo_apuesta_id: retirar_tipo)
                    if enjuego.present?
                      enjuego.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
                      enjuego.each { |enj|
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.status == 1
                          OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone, descripcion: "No entra en juego: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          busca_user = buscar_cliente_cajero(id_propone)
                          if busca_user != "0"
                            if enj.id_propone == enj.id_juega
                              tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                              reference_id_propone = enj.reference_id_juega
                            else
                              tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                              reference_id_propone = enj.reference_id_banquea
                            end
                            set_envios_api(5, busca_user, tickets_detalle_id_propone, reference_id_propone, enj.monto.to_f, "No en tra en juego")
                          end
                        else
                          if enj.id_juega == enj.id_propone
                            monto_banqueado = enj.cuanto_gana_completo.to_f
                            cuanto_juega = enj.monto.to_f
                          else
                            monto_banqueado = enj.monto.to_f
                            cuanto_juega = enj.cuanto_gana_completo.to_f
                          end
                          retirados_propuestas << enj.id
                          retirados_enjuego << enj.id
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          busca_user = buscar_cliente_cajero(id_quien_juega)
                          if busca_user != "0"
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_juega.to_f, "No entra en juego")
                          end
                          busca_user = buscar_cliente_cajero(id_quien_banquea)
                          if busca_user != "0"
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, monto_banqueado.to_f, "No entra en juego")
                          end
                        end
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
        end
      rescue StandardError => e
        #       pase_correo(e.message,e.backtrace.inspect)
      end
    end


    def retirar_ejemplar_logros(hip_id, carrera_id, caballo)
      caballos = [caballo]
      todos_caballos_nombre = true
      arreglo_enjuego = []
      arreglo_propuestas = []
      retirados_propuestas = []
      retirados_enjuego = []
      hipodromo = Hipodromo.find_by(abreviatura: hip_id)
      carrera_bus = Hipodromo.find_by(abreviatura: hip_id).jornada.last.carrera.find_by(numero_carrera: carrera_id)
      cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_bus.id, retirado: false).count - 1
      retirar_tipo = []
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
      carr = carrera_bus
      begin
        if caballos.count > 0
          caballos.each { |cab|
            buscar = CaballosCarrera.find_by(carrera_id: carr.id, numero_puesto: cab, retirado: false)
            if buscar.present?
                buscar.update(retirado: true)
                if cab["retirado"] and buscar.retirado == false
                  buscar.update(retirado: true)
                  bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo.id, carrera_id: carr.id, caballos_carrera_id: buscar.id)
                  if bus_cab_ret_api.present?
                    bus_cab_ret_api.update(status: 2, user_id: session[:usuario_actual]["id"])
                  end
                  enjuego = PropuestasCaballo.where(caballos_carrera_id: buscar.id, status: [1, 2])
                  if enjuego.present?
                    enjuego.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
                    enjuego.each { |enj|
                      if enj.status == 1
                        OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                        busca_user = buscar_cliente_cajero(enj.id_propone)
                        if busca_user != "0"
                          if enj.id_propone == enj.id_juega
                            tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                            reference_id_propone = enj.reference_id_juega
                          else
                            tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                            reference_id_propone = enj.reference_id_banquea
                          end
                          set_envios_api(3, busca_user, tickets_detalle_id_propone, reference_id_propone, enj.monto.to_f, "Devolucion/Retirado")
                        end
                      else
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.id_juega == enj.id_propone
                          monto_banqueado = enj.cuanto_gana_completo.to_f
                          cuanto_juega = enj.monto.to_f
                        else
                          monto_banqueado = enj.monto.to_f
                          cuanto_juega = enj.cuanto_gana_completo.to_f
                        end
                        retirados_propuestas << enj.id
                        retirados_enjuego << enj.id
                        OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                        OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                        busca_user = buscar_cliente_cajero(id_quien_juega)
                        if busca_user != "0"
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_juega.to_f, "Devolucion/Retirado")
                        end
                        busca_user = buscar_cliente_cajero(id_quien_banquea)
                        if busca_user != "0"
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, monto_banqueado.to_f, "Devolucion/Retirado")
                        end
                      end
                    }
                  end
                  if retirar_tipo.length > 0
                    enjuego = PropuestasCaballo.where(carrera_id: carrera_id, activa: false, status: 2, tipo_apuesta_id: retirar_tipo)
                    if enjuego.present?
                      enjuego.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
                      enjuego.each { |enj|
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.status == 1
                          OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone, descripcion: "No entra en juego: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          busca_user = buscar_cliente_cajero(id_propone)
                          if busca_user != "0"
                            if enj.id_propone == enj.id_juega
                              tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                              reference_id_propone = enj.reference_id_juega
                            else
                              tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                              reference_id_propone = enj.reference_id_banquea
                            end
                            set_envios_api(5, busca_user, tickets_detalle_id_propone, reference_id_propone, enj.monto.to_f, "No en tra en juego")
                          end
                        else
                          if enj.id_juega == enj.id_propone
                            monto_banqueado = enj.cuanto_gana_completo.to_f
                            cuanto_juega = enj.monto.to_f
                          else
                            monto_banqueado = enj.monto.to_f
                            cuanto_juega = enj.cuanto_gana_completo.to_f
                          end
                          retirados_propuestas << enj.id
                          retirados_enjuego << enj.id
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega, descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea, descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          busca_user = buscar_cliente_cajero(id_quien_juega)
                          if busca_user != "0"
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_juega.to_f, "No entra en juego")
                          end
                          busca_user = buscar_cliente_cajero(id_quien_banquea)
                          if busca_user != "0"
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, monto_banqueado.to_f, "No entra en juego")
                          end
                        end
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
        end
      rescue StandardError => e
        #       pase_correo(e.message,e.backtrace.inspect)
      end
    end



    def validar_json(json)
      JSON.parse(json)
    rescue JSON::ParserError => e
      false
    end


  end
end