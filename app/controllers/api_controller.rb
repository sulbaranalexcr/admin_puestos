class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def close_race
    begin
      CierreLog.create(parametros: params.to_json)
      integrador_in = params[:integrator_id].to_i
      api_key_in = params[:api_key]
      integrator = verificar_integrador(integrador_in, api_key_in)
      render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

      numero_carrera = params[:race_number].to_i
      hipodromo_id = params[:racecourse_track_id]
      hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)
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

      carrera = bus_carrera
      carrera_id = bus_carrera.id
      carrera.update(activo: false)
      hipodromo_id = carrera.jornada.hipodromo.id
      CierreCarrera.create(hipodromo_id: hipodromo_id, carrera_id: bus_carrera.id, user_id: 0)
      CierresApi.create(es_api: true, hipodromo_id: hipodromo.id, carrera_id: bus_carrera.id)
      propuestas = Propuesta.where(carrera_id: carrera_id, activa: true, created_at: Time.now.all_day)
      if propuestas.present?
        propuestas.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
        propuestas.each do |prop|
          OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id,
                                   descripcion: "Reverso por carrera cerrada prop: #{prop.id}", monto: prop.monto, status: 0, moneda: prop.moneda)
        end
      end
      CerrarCarreraApiJob.perform_async propuestas.pluck(:id), hipodromo_id, carrera_id
      @proximas = Carrera.where("hora_carrera > '#{Time.now.strftime('%H:%M')}'").where(
        jornada_id: Jornada.where(fecha: Time.now.all_day).ids, activo: true
      ).order(:hora_carrera).limit(10)
      redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id,
                                                                                                            :hora_carrera, :hora_pautada)
      redis.set('cierre_carre', horas_carrera.to_json)
      horas_min = []
      horas_carrera.each do |hc|
        if hc[1] != ''
          horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1),
                         'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
        end
      end
      @mintos_restantes = horas_min.to_json
      render json: { 'code' => 1, 'msg' => 'Carrera cerrada con exito.' }
    rescue StandardError => e
      logger.info('***************************************************')
      logger.info(e.message)
      logger.info(e.backtrace.inspect)
      logger.info('***************************************************')
      ErroresCierre.create(mensaje: e.message, mensaje2: e.backtrace.inspect, parametros: params)
      render json: { 'code' => -10, 'msg' => 'Error Interno.' }, status: 400 and return
    end

    ActionCable.server.broadcast 'publicas_deporte_channel',
                                 { data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS', 'id' => bus_carrera.id } }
    # eliminar este bloque al verificar ya que es viejo
    # begin
    #   # devolver_apuestas_caballo_deportes(hipodromo.id, bus_carrera.id, 1)
    # rescue Exception => e
    #   logger.info('***************************************************')
    #   logger.info(e.message)
    #   logger.info(e.backtrace.inspect)
    #   logger.info('***************************************************')
    # end
  end

  def verificar_retirado(data, numero_caballo)
    data.find { |ret| ret.to_s == numero_caballo.to_s }
  end

  def invalidate_horse
    integrador_in = params[:integrator_id].to_i
    api_key_in = params[:api_key]
    integrator = verificar_integrador(integrador_in, api_key_in)
    render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

    hipodromo_id = params[:racecourse_track_id]
    numero_carrera = params[:race_number].to_i
    numero_caballo = params[:horse_number]
    hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)

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

    return unless hipodromo.activo

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

    render json: { 'code' => 1, 'msg' => 'Caballo retirado con exito.' }
    datos_retiro = retirar_ejemplar(hipodromo_id, numero_carrera, numero_caballo)
    if datos_retiro[0].length.positive? || datos_retiro[1].length.positive?
      RetirarCaballosApiJob.perform_async datos_retiro, hipodromo.id, bus_carrera.id
    end
    ActionCable.server.broadcast 'publicas_deporte_channel',
                                 { data: { 'tipo' => 'RETIRAR_CABALLOS', 'id' => buscar_caballo.id } }
    # eliminar este bloque al verificar ya que es viejo
    # devolver_apuestas_caballo_deportes(hipodromo.id, bus_carrera.id, 2)
  end

  def notify_scratches(hipodromo_id, numero_carrera, numero_caballo, status = 1)
    ActionCable.server.broadcast 'web_notifications_banca_channel', { data: { 'tipo' => 2501 } }
    retirar_pendiente(hipodromo_id, numero_carrera, numero_caballo, status)
  end

  def retirar_pendiente(hip, carr, cab, status = 1)
    hipodromos_buscar = Hipodromo.find_by(abreviatura: hip)
    carrera_bus = hipodromos_buscar.jornada.last.carrera.find_by(numero_carrera: carr)
    bus_cab = carrera_bus.caballos_carrera.find_by(numero_puesto: cab)
    buscar = CaballosRetiradosConfirmacion.where(hipodromo_id: hipodromos_buscar.id, carrera_id: carrera_bus.id,
                                                 caballos_carrera_id: bus_cab.id)
    return if buscar.present?

    CaballosRetiradosConfirmacion.create(hipodromo_id: hipodromos_buscar.id, carrera_id: carrera_bus.id,
                                         caballos_carrera_id: bus_cab.id, status: status)
  end

  def color_celda_caballo
    {
      '1' => { 'fondo' => '#ff1100', 'letra' => '#ffffff' },
      '2' => { 'fondo' => '#fcfdfc', 'letra' => '#000000' },
      '3' => { 'fondo' => '#2659c2', 'letra' => '#ffffff' },
      '4' => { 'fondo' => '#f7eb00', 'letra' => '#000000' },
      '5' => { 'fondo' => '#00aa4f', 'letra' => '#ffffff' },
      '6' => { 'fondo' => '#35373a', 'letra' => '#f7eb00' },
      '7' => { 'fondo' => '#f47e37', 'letra' => '#000000' },
      '8' => { 'fondo' => '#f8b6c3', 'letra' => '#000000' },
      '9' => { 'fondo' => '#00b5af', 'letra' => '#000000' },
      '10' => { 'fondo' => '#6510b3', 'letra' => '#ffffff' },
      '11' => { 'fondo' => '#7c8180', 'letra' => '#ff1100' },
      '12' => { 'fondo' => '#82c341', 'letra' => '#333333' },
      '13' => { 'fondo' => '#5c2913', 'letra' => '#ffffff' },
      '14' => { 'fondo' => '#760c30', 'letra' => '#f7eb00' },
      '15' => { 'fondo' => '#b4a87d', 'letra' => '#333333' },
      '16' => { 'fondo' => '#2b547e', 'letra' => '#fff' },
      '17' => { 'fondo' => 'navy', 'letra' => '#fff' },
      '18' => { 'fondo' => '#4e9258', 'letra' => '#fff' },
      '19' => { 'fondo' => '#c2dfff', 'letra' => '#000' },
      '20' => { 'fondo' => '#e4287c', 'letra' => '#fff' },
      '21' => { 'fondo' => '#e4287c', 'letra' => '#fff' },
      '22' => { 'fondo' => '#e4287c', 'letra' => '#fff' },
      '23' => { 'fondo' => '#e4287c', 'letra' => '#fff' },
      '24' => { 'fondo' => '#e4287c', 'letra' => '#fff' },
      '25' => { 'fondo' => '#e4287c', 'letra' => '#fff' }
    }
  end

  def activate_horse
    integrador_in = params[:integrator_id].to_i
    api_key_in = params[:api_key]
    integrator = verificar_integrador(integrador_in, api_key_in)
    render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

    hipodromo_id = params[:racecourse_track_id]
    numero_carrera = params[:race_number].to_i
    numero_caballo = params[:horse_number]
    hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)
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

    buscar_caballo.update(retirado: false)
    render json: { 'code' => 1, 'msg' => 'Caballo activado con exito.' }
  end

  def verificar_integrador(integrador_in, api_key_in)
    Integrador.find_by(id: integrador_in, api_key: api_key_in, activo: true)
  end

  def post_time
    integrador_in = params[:integrator_id].to_i
    api_key_in = params[:api_key]
    integrator = verificar_integrador(integrador_in, api_key_in)
    render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

    hipodromo_id = params[:racecourse_track_id]
    numero_carrera = params[:race_number].to_i
    minutos = params[:minutes].to_i
    hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)
    render json: { 'code' => -1, 'msg' => 'Hipodromo no existe.' }, status: 400 and return unless hipodromo.present?

    bus_jornada = hipodromo.jornada.where(fecha: Time.now.all_day)
    unless bus_jornada.present?
      render json: { 'code' => -1, 'msg' => 'Jornada no creada para la fecha.' }, status: 400 and return
    end

    bus_carrera = bus_jornada.last.carrera.find_by(numero_carrera: numero_carrera)
    unless bus_carrera.present?
      render json: { 'code' => -1, 'msg' => "Carrera #{numero_carrera} no existe." }, status: 400 and return
    end

    hora_actual = bus_carrera.hora_carrera.to_time
    hora_nueva = hora_actual + minutos.minutes
    Postime.create(user_id: 1, hora_anterior: bus_carrera.hora_carrera, nueva_hora: hora_nueva.strftime('%H:%M:%S'),
                   carrera_id: bus_carrera.id)
    bus_carrera.update(hora_carrera: hora_nueva.strftime('%H:%M:%S'))
    render json: { 'code' => 1, 'msg' => 'Post Time aplicado con exito.' }
    redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
    horas_carrera = Carrera.where(jornada_id: Jornada.where(fecha: Time.now.all_day), activo: true).pluck(:id,
                                                                                                          :hora_carrera, :hora_pautada)
    redis.set('cierre_carre', horas_carrera.to_json)
    horas_min = []
    horas_carrera.each do |hc|
      if hc[1] != ''
        horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1),
                       'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    end
    ActionCable.server.broadcast 'publicas_channel', { data: { 'tipo' => 1, 'hora' => horas_min } }
  end

  def award_race
    integrador_in = params[:integrator_id].to_i
    api_key_in = params[:api_key]
    integrator = verificar_integrador(integrador_in, api_key_in)
    render json: { 'code' => -1, 'msg' => 'Integrador no valido.' }, status: 400 and return unless integrator.present?

    hipodromo_id = params[:racecourse_track_id]
    resultados = params[:result]
    numero_carrera = resultados['0']['racecourse_race_number'].to_i
    hipodromo = Hipodromo.find_by(abreviatura: hipodromo_id)
    render json: { 'code' => -1, 'msg' => 'Hipodromo no existe.' }, status: 400 and return unless hipodromo.present?

    bus_jornada = hipodromo.jornada.where(fecha: Time.now.all_day)
    unless bus_jornada.present?
      render json: { 'code' => -1, 'msg' => 'Jornada no creada para la fecha.' }, status: 400 and return
    end

    bus_carrera = bus_jornada.last.carrera.find_by(numero_carrera: numero_carrera)
    unless bus_carrera.present?
      render json: { 'code' => -1, 'msg' => "Carrera #{numero_carrera} no existe." }, status: 400 and return
    end

    if hipodromo.activo
      carrera_id_nyra = Hipodromos::Carreras.extrac_nyra_id_race(hipodromo, numero_carrera)
      PremiacionService::Api.carrera(bus_carrera.id, hipodromo.codigo_nyra, numero_carrera, carrera_id_nyra)
    end
    render json: { 'code' => 1, 'msg' => 'Resultados recibidos.' }
  rescue StandardError
    render json: { 'code' => -1, 'msg' => 'Algo salio mal, revise los parametros.' }, status: 400
  end

  def get_currencys
    integrador_in = params[:integrator_id].to_i
    api_key_in = params[:api_key]
    integrator = verificar_integrador(integrador_in, api_key_in)
    if integrator.present?
      monedas_disponibles = FactorCambio.where(grupo_id: integrator.grupo_id).pluck(:moneda_id)
      unless monedas_disponibles.present?
        render json: { 'code' => -2, 'msg' => 'No hay monedas configurada.', 'status' => 400 }, status: 400 and return
      end

      monedas = Moneda.where(id: monedas_disponibles)
      datos = []
      monedas.each do |mon|
        factor = FactorCambio.find_by(grupo_id: integrator.grupo_id, moneda_id: mon.id)
        datos << { 'id' => mon.id, 'country' => mon.pais, 'abbreviation' => mon.abreviatura,
                   'exchange_rate' => factor.valor_dolar }
      end
      render json: { 'code' => 1, 'msg' => 'Transaccion completada.', 'currencys' => datos, 'status' => 200 }
    else
      render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 and return
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
      obtenet_data = request.location.data
      moneda_disponible = FactorCambio.find_by(grupo_id: integrator.grupo_id, moneda_id: moneda_entrante)
      unless moneda_disponible.present?
        render json: { 'code' => -3, 'msg' => 'Moneda no configurada.', 'status' => 400 }, status: 400 and return
      end

      moneda = Moneda.find(moneda_entrante)
      monto_antrior = moneda_disponible.valor_dolar.to_f.round(2)
      moneda_disponible.update(valor_dolar: monto_entrada)
      HistorialTasa.create(user_id: User.where(grupo_id: integrator.grupo_id).last.id, moneda_id: moneda_entrante,
                           tasa_anterior: monto_antrior.to_f.round(2), tasa_nueva: monto_entrada, ip_remota: request.remote_ip, grupo_id: integrator.grupo_id, geo: obtenet_data.to_json)
      datos = { 'id' => moneda.id, 'country' => moneda.pais, 'abbreviation' => moneda.abreviatura,
                'exchange_rate_previous' => monto_antrior, 'exchange_rate_current' => moneda_disponible.valor_dolar.to_f.round(2) }
      render json: { 'code' => 2, 'msg' => 'Transaccion completada.', 'currency' => datos, 'status' => 200 }
    else
      render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 and return
    end
  end

  def get_currency_interno(grupo_id, id)
    monedas = Moneda.find_by(id: id)
    factor = FactorCambio.find_by(grupo_id: grupo_id, moneda_id: id)
    if factor.present?
      [monedas.abreviatura, factor.valor_dolar.to_f]
    else
      []
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
      render json: { 'code' => 1, 'msg' => 'Transaccion completada.', 'status' => 200 } and return
    else
      render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 and return
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
            render json: { 'code' => -4, 'msg' => 'Moneda no configurada para tipo de cambio.', 'status' => 400 },
                   status: 400 and return
          end

          datos = {
            'id' => user.id,
            'name' => user.nombre,
            'alias' => user.alias,
            'email' => user.correo,
            'proposes' => user.propone,
            'take' => user.toma,
            'commission' => user.comision.to_f,
            'active' => user.activo,
            'limits' => {
              'usd' => {
                'min_bet_usd' => user.jugada_minima_usd,
                'max_bet_usd' => user.jugada_maxima_usd
              },
              'requested_currency' => {
                'min_bet' => (user.jugada_minima_usd * consulta_moneda[1].to_f),
                'max_bet' => (user.jugada_maxima_usd * consulta_moneda[1].to_f),
                'requested_currency' => consulta_moneda[0],
                'exchange_rate' => consulta_moneda[1]
              }
            }
          }

          render json: { 'code' => 10, 'msg' => 'Transaccion completada.', 'data' => datos, 'status' => 200 } and return
        else
          datos = {
            'id' => user.id,
            'name' => user.nombre,
            'alias' => user.alias,
            'email' => user.correo,
            'proposes' => user.propone,
            'take' => user.toma,
            'commission' => user.comision.to_f,
            'active' => user.activo,
            'limits' => {
              'usd' => {
                'min_bet_usd' => user.jugada_minima_usd,
                'max_bet_usd' => user.jugada_maxima_usd
              },
              'requested_currency' => {
                'min_bet' => user.jugada_minima_usd,
                'max_bet' => user.jugada_maxima_usd,
                'requested_currency' => 'USD',
                'exchange_rate' => 1
              }
            }
          }

          render json: { 'code' => 10, 'msg' => 'Transaccion completada.', 'data' => datos, 'status' => 200 } and return
        end
      else
        render json: { 'code' => -2, 'msg' => 'Error al validar usuario, verifique los datos', 'status' => 400 },
               status: 400 and return
      end
    else
      render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 and return
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
            render json: { 'code' => -4, 'msg' => 'Moneda no configurada para tipo de cambio.', 'status' => 400 },
                   status: 400 and return
          end

          maxima_convertida = (juada_maxima / consulta_moneda[1].to_f).round(3)
          minima_convertida = (juada_minima / consulta_moneda[1].to_f).round(3)
          propone = user.propone unless propone.present?
          toma = user.toma unless toma.present?
          comision = user.comision unless comision.present?
          activo = user.activo unless activo.present?

          user.update(propone: propone, toma: toma, comision: comision, activo: activo,
                      jugada_minima_usd: minima_convertida, jugada_maxima_usd: maxima_convertida)
          datos = {
            'id' => user.id,
            'name' => user.nombre,
            'alias' => user.alias,
            'email' => user.correo,
            'proposes' => user.propone,
            'take' => user.toma,
            'commission' => user.comision.to_f,
            'active' => user.activo,
            'limits' => {
              'usd' => {
                'min_bet_usd' => user.jugada_minima_usd,
                'max_bet_usd' => user.jugada_maxima_usd
              },
              'requested_currency' => {
                'min_bet' => (user.jugada_minima_usd * consulta_moneda[1].to_f),
                'max_bet' => (user.jugada_maxima_usd * consulta_moneda[1].to_f),
                'requested_currency' => consulta_moneda[0],
                'exchange_rate' => consulta_moneda[1]
              }
            }
          }

          render json: { 'code' => 10, 'msg' => 'Transaccion completada.', 'data' => datos, 'status' => 200 } and return
        else
          user.update(propone: propone, toma: toma, comision: comision, activo: activo,
                      jugada_minima_usd: juada_minima.round(3), jugada_maxima_usd: juada_maxima.round(3))
          datos = {
            'id' => user.id,
            'name' => user.nombre,
            'alias' => user.alias,
            'email' => user.correo,
            'proposes' => user.propone,
            'take' => user.toma,
            'commission' => user.comision.to_f,
            'active' => user.activo,
            'limits' => {
              'usd' => {
                'min_bet_usd' => user.jugada_minima_usd,
                'max_bet_usd' => user.jugada_maxima_usd
              },
              'requested_currency' => {
                'min_bet' => user.jugada_minima_usd,
                'max_bet' => user.jugada_maxima_usd,
                'requested_currency' => 'USD',
                'exchange_rate' => 1
              }
            }
          }

          render json: { 'code' => 10, 'msg' => 'Transaccion completada.', 'data' => datos, 'status' => 200 } and return
        end
      else
        render json: { 'code' => -2, 'msg' => 'Error al validar usuario, verifique los datos', 'status' => 400 },
               status: 400 and return
      end
    else
      render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 and return
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
        caballos.each do |cab|
          buscar = CaballosCarrera.find_by(carrera_id: carr.id, numero_puesto: cab, retirado: false)
          next unless buscar.present?

          buscar.update(retirado: true)
          # ############enjuego###############
          enjuego = Enjuego.where(
            propuesta_id: Propuesta.where(caballo_id: buscar.id, activa: false, created_at: Time.now.all_day,
                                          status: 2).ids, activo: true, created_at: Time.now.all_day
          )
          if enjuego.present?
            enjuego.update_all(activa: false, status: 2, status2: 13, updated_at: DateTime.now)
            enjuego.each do |enj|
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
              OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                                       descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
              OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                                       descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
            end
          end
          if retirar_tipo.length > 0
            enjuego = Enjuego.where(
              propuesta_id: Propuesta.where(carrera_id: carrera_id, activa: false, created_at: Time.now.all_day, status: 2,
                                            tipo_id: retirar_tipo).ids, activo: true, created_at: Time.now.all_day
            )
            if enjuego.present?
              enjuego.update_all(activa: false, status: 2, status2: 7, updated_at: DateTime.now)
              enjuego.each do |enj|
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
                OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                                         descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                                         descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
              end
            end
          end

          # ############fin enjuego###########
          prupuestas = Propuesta.where(caballo_id: buscar.id, status: 1, created_at: Time.now.all_day)
          if prupuestas.present?
            prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
            prupuestas.each do |prop|
              prop.update(activa: false, status: 4, status2: 13) if (prop.status == 2) || (prop.status == 1)
              tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
              arreglo_propuestas << prop.id
              retirados_propuestas << prop.id
              OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id,
                                       descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
            end
          end

          next unless retirar_tipo.length > 0

          prupuestas = Propuesta.where(carrera_id: carrera_id, status: 1, created_at: Time.now.all_day,
                                       tipo_id: retirar_tipo)
          next unless prupuestas.present?

          prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
          prupuestas.each do |prop|
            prop.update(activa: false, status: 4, status2: 7) if (prop.status == 2) || (prop.status == 1)
            tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
            arreglo_propuestas << prop.id
            retirados_propuestas << prop.id
            OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id,
                                     descripcion: "Devolucion/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
          end
        end
      end
      [retirados_propuestas, retirados_enjuego]
    rescue StandardError => e
    end
  end

  def filtrar_por_hipodromo_interno(carrera, cabid, moneda, puesto)
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

    redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
    horas_carrera = JSON.parse(redis.get('cierre_carre'))
    horas_min = []
    horas_carrera.each do |hc|
      if hc[1] != ''
        horas_min << { 'id' => hc[0], 'resta' => ((hc[1].to_time - Time.now.to_time) / 60).round(1),
                       'resta_taq' => ((hc[2].to_time - Time.now.to_time) / 60).round(1) }
      end
    end

    colores_celda = color_celda_caballo[puesto.to_i.to_s]
    @caballos << { 'id' => cab.id, 'colores_celda' => colores_celda, 'puesto' => cab.numero_puesto,
                   'caballo' => cab.nombre.gsub("'", "\`").gsub("'", '.'), 'jugadas_bs' => juegan.last(3), 'jugadas_usd' => juegan2.last(3), 'banqueadas_bs' => juegan3, 'banqueadas_usd' => juegan4, 'enjuego_bs' => juegan5, 'enjuego_usd' => juegan6, 'retirado' => cab.retirado, 'minutos_resta' => horas_min, 'moneda' => moneda }
    @caballos
  end

  def mensaje_devolucion(idioma, tipo)
    mensaje = ''
    case tipo
    when 1
      mensaje = if idioma == 'en'
                  'Refund of money/NM.'
                else
                  'Devolucion de dinero/NC.'
                end
    when 2
      mensaje = if idioma == 'en'
                  'Horse retired.'
                else
                  'Caballo retirado.'
                end
    end
    mensaje
  end

  def generate_demo
    search = UsuariosTaquilla.where(integrador_id: params[:integrator_id])
    if search.present?
      hmac_secret = 'bet$xChanges'
      search.first.update(token: crear_token)
      payload = { email: search.first.correo, token: search.first.token, integrator_id: search.first.integrador_id, user_id: search.first.cliente_id }
      token_json = JWT.encode(payload, hmac_secret, 'HS256')
      render json: { status: 1, token: token_json }
    else
      render json: { status: 0, message: 'No se encontro usuario demo.' }, status: :unprocessable_entity
    end
  end

  def crear_token
    token_nuevo = SecureRandom.urlsafe_base64(50)
    buscar_existe = UsuariosTaquilla.find_by(token: token_nuevo)
    if buscar_existe
      crear_token
    else
      token_nuevo
    end
  end

  # eliminar este bloque al verificar ya que es viejo
  # def devolver_apuestas_caballo_deportes(hipodromo_id, carrera_id, tipo)
  #   # tipo   1 = carrera cerrada  2 = Retirar caballo
  #   case tipo
  #   when 1
  #     estatus = 1
  #   when 2
  #     estatus = [1, 2, 3]
  #   end

  #   ActiveRecord::Base.transaction do
  #     propuestas = PropuestasCaballo.where(hipodromo_id: hipodromo_id, carrera_id: carrera_id,
  #                                          created_at: Time.now.all_day, tipo_apuesta: 1, status: estatus)
  #     if propuestas.present?
  #       propuestas.each do |prop|
  #         estatus_anterior = prop.status
  #         if prop.status == 2
  #           prop.update(activa: false, status: 20, status2: 7)
  #         else
  #           prop.update(activa: false, status: 7, status2: 7)
  #         end
  #         if estatus_anterior == 1
  #           usuario = UsuariosTaquilla.find(prop.id_propone)
  #           monto = prop.monto.to_f.round(2)
  #           idioma = usuario.idioma
  #           tipo_logro = usuario.tipo_logro
  #           mensaje = mensaje_devolucion(idioma, tipo)
  #           actualizar_saldos(prop.id_propone.to_i, mensaje + " (#{prop.detalle_jugada(idioma, tipo_logro)})", monto,
  #                             2, prop.id, 2)
  #         else
  #           usuario_juega = UsuariosTaquilla.find(prop.id_juega)
  #           usuario_banquea = UsuariosTaquilla.find(prop.id_banquea)
  #           idioma1 = usuario_juega.idioma
  #           idioma2 = usuario_banquea.idioma
  #           tipo_logro1 = usuario_juega.tipo_logro
  #           tipo_logro2 = usuario_banquea.tipo_logro
  #           mensaje1 = mensaje_devolucion(idioma1, tipo)
  #           mensaje2 = mensaje_devolucion(idioma2, tipo)
  #           if prop.accion_id == 1
  #             monto_juega = prop.monto.to_f.round(2)
  #             monto_banquea = prop.cuanto_gana_completo.to_f.round(2)
  #           else
  #             monto_juega = prop.cuanto_gana_completo.to_f.round(2)
  #             monto_banquea = prop.monto.to_f.round(2)
  #           end
  #           actualizar_saldos(prop.id_juega.to_i, mensaje1 + " (#{prop.detalle_jugada(idioma1, tipo_logro1)})",
  #                             monto_juega, 2, prop.id, 2)
  #           actualizar_saldos(prop.id_banquea.to_i, mensaje2 + " (#{prop.detalle_jugada(idioma2, tipo_logro2)})",
  #                             monto_banquea, 2, prop.id, 2)
  #         end
  #       end
  #     end
  #   end
  # end

  def validar_json(json)
    JSON.parse(json)
  rescue JSON::ParserError => e
    false
  end

  def operations_failds
    json_datos = '{"a":10}'
    validar = validar_json(json_datos)
    if validar.present?
      render json: { 'status' => 'OK', 'code' => 200, 'msg' => 'Received' }
    else
      render json: { 'status' => 'FAILD', 'code' => 400, 'msg' => 'JSON parser error in params' }, status: 400
    end
  end

  def actualizar_saldos(usuario_id, descripcion, monto, moneda, _enj_id, tipo = 3)
    opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto,
                                     status: 0, moneda: moneda, tipo: tipo, tipo_app: 2)
    (@ids_ganadores ||= []) << usuario_id
  end
end
