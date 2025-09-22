module ApplicationHelper
  def update_cierre_carrera(cierre)
    case cierre.user_id
    when -1
      'Banca'
    when 0
      'Api'
    else
      cierre.user.username
    end
  end

  def update_saldos_taquilla(usuarios_retiro)
    # saldos_enviar = UsuariosTaquilla.where(id: usuarios_retiro).pluck(:id, :saldo_usd)
    # ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'UPDATE_SALDOS_PREMIOS', 'data' => saldos_enviar }}
  end

  def menu_hipodromos_helper
    hipodromos = []
    hipodromos_bus = Hipodromo.where(activo: true,
                                     id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id)).order(:nombre)
    hipodromos_bus.each do |hip|
      carreras_array = []
      hip.jornada.last.carrera.where(activo: true).order(:id).each do |car|
        if car.hora_carrera.length.positive?
          carreras_array << [car.id, car.numero_carrera, car.utc.to_time.strftime('%Y-%m-%d %H:%M'), car.distance, car.purse, car.name] if car.hora_carrera.to_time >= Time.now
        end
      end
      if carreras_array.length > 0
        hipodromos << { 'id' => hip.id, 'nombre' => hip.nombre, 'carreras' => carreras_array, 'tipo' => hip.tipo, 'pais' => hip.pais, 'bandera' => hip.bandera }
      end
    end

    hipodromos
  end

  def menu_deportes_helper(deporte_id)
    deportes = []
    juego = Juego.find_by(juego_id: deporte_id)
    match_todos = Match.select(:id, :nombre, :juego_id, :liga_id, :utc).where(juego_id: deporte_id, activo: true).where(
      'local >= ? and local <= ?', Time.now, Time.now.end_of_day
    ).order(:local)
    ligas = []
    Liga.where(juego_id: juego.juego_id, activo: true).order(:nombre).each do |liga|
      matchs = []
      match_todos.select { |a| a['liga_id'] == liga.liga_id }.each do |match|
        if match['nombre'].length > 0
          matchs << { 'id' => match['id'], 'nombre' => match['nombre'], 'utc' => match['utc'] }
        end
      end
      if matchs.length > 0
        ligas << { 'id' => liga.liga_id, 'nombre' => liga.nombre, 'matchs' => matchs, 'activa' => true }
      end
    end
    ligas
  end

  # 1- Premiar tipo
  # 3- Retirar caballos
  # 4- cerrar_carrera
  # 5- No entra en juego

  def set_envios_api(tipo, user_id, transaction_id, reference_id, monto, details = '', comis = 0, agente)
    monto_t = monto_local(user_id[1], monto)
    comis = monto_local(user_id[1], comis).to_f.round(2)
    case tipo.to_i
    when 1
      @premios_array_cajero << { 'id' => user_id[0], 'taq_id' => user_id[1], 'transaction_id' => transaction_id,
                                 'reference_id' => reference_id, 'amount' => monto_t, 'details' => details, 
                                 'pay_amount' => comis, 'loser' => agente }
    when 3
      @retirar_array_cajero << { 'id' => user_id[0], 'taq_id' => user_id[1], 'transaction_id' => transaction_id,
                                 'reference_id' => reference_id, 'amount' => monto_t, 'details' => details }
    when 4
      @cierrec_array_cajero << { 'id' => user_id[0], 'taq_id' => user_id[1], 'transaction_id' => transaction_id,
                                 'reference_id' => reference_id, 'amount' => monto_t, 'details' => details }
    when 5
      @nojuega_array_cajero << { 'id' => user_id[0], 'taq_id' => user_id[1], 'transaction_id' => transaction_id,
                                 'reference_id' => reference_id, 'amount' => monto_t, 'details' => details }
    end
  end

  def buscar_cliente_cajero(id)
    busqueda = @ids_cajero_externop.select { |a| a['id'] == id }
    if busqueda.present?
      [busqueda[0]['cliente_id'], busqueda[0]['id']]
    else
      @usuarios_interno_ganan << id unless @usuarios_interno_ganan.include?(id)
      '0'
    end
  end

  def monto_local(id, monto)
    bus_mon = @todos_ids.select { |bmt| bmt['id'] == id }
    if bus_mon.present?
      if bus_mon[0]['valor_moneda'].to_f > 0
        monto.to_f * bus_mon[0]['valor_moneda'].to_f
      else
        monto.to_f
      end
    else
      monto.to_f
    end
  end

  def status_propuestas(id)
    case id.to_i
    when 1
      %w[Propuesta Propuesta]
    when 2
      %w[Cruzada Cruzada]
    when 3
      ['Cruzada en corte', 'Cruzada en corte']
    when 4
      %w[Cortada Cortada]
    when 5
      ['Propuesta por Corte', 'Propuesta por Corte']
    when 6
      %w[Eliminada Eliminada]
    when 7
      %w[Devuelta Devuelta]
    when 8
      %w[Gano Perdio]
    when 9
      %w[Perdio Gano]
    when 10
      %w[Empato Empato]
    when 11
      ['Gano Mitad', 'Perdio Mitad']
    when 12
      ['Perdio Mitad', 'Gano Mitad']
    when 13
      %w[Retirado Retirado]
    when 14
      %w[Devuelta Devuelta]
    end
  end

  def text_status2(id)
    case id.to_i
    when 1
      'Propuesta'
    when 2
      'Cruzada'
    when 3
      'Cruzada en corte'
    when 4
      'Cortada'
    when 5
      'Propuesta por Corte'
    when 6
      'Eliminada'
    when 7
      'Devuelta'
    when 8
      'Gano'
    when 9
      'Perdio'
    when 10
      'Empato'
    when 11
      'Gano Mitad'
    when 12
      'Perdio Mitad'
    when 13
      'Retirado'
    when 14
      'Devuelta'
    end
  end

  def tipo_reporte_cajero(id)
    case id.to_i
    when 1
      'Premiacion'
    when 2
      ''
    when 3
      'Retirados'
    when 4
      'Carrera Cerrada'
    when 5
      'No entra en juego'
    when 6
      'Eliminadas'
    end
  end

  def tipo_resultado(id)
    case id.to_i
    when 1
      'Completo'
    when 2
      'Incompleto Valido'
    when 3
      'Cancelado'
    end
  end

  def buscar_data_api(metodo)
    require 'net/http'
    require 'uri'

    begin
      uri = URI('http://62.171.137.78:8080/api/v1/' + metodo)
      res = Net::HTTP.get(uri)
      datos = JSON.parse(res)['json']
      if datos.length > 0
        datos
      else
        []
      end
    rescue StandardError => e
      []
    end
  end

  def tiene_acceso?(opcion)
    opciones = MenuUsuario.find_by(user_id: session[:usuario_actual]['id'])
    if opciones.present?
      menu = JSON.parse(opciones.menu)
      encontrado = false
      alex = ''
      menu.each do |_men, val|
        val['menu'].each do |a, _b|
          if (a['path'] == opcion) && a['activo']
            encontrado = true
            alex = a
          end
        end
      end
      if encontrado
        true
      else
        false
      end
    else
      false
    end
  end

  def seguridad_cuentas
    ruta_buscar = if request.path.include?('/edit') || request.path.include?('/new')
                    '/' + request.path.split('/')[1]
                  else
                    request.path
                  end
    ruta_buscar = '/solicitudes/retiros' if request.path.include?('/solicitudes/retiros')

    ruta_buscar = '/solicitudes/recargas' if request.path.include?('/solicitudes/recargas')

    redirect_to '/login' and return unless tiene_acceso? ruta_buscar
  end

  def set_tipo(id)
    case id
    when 1
      'Ahorros'
    when 2
      'Corriente'
    when 3
      'Fal'
    when 4
      'Crypto Moneda'
    end
  end

  def current_user(user = User)
    token = session[:token]
    @current_user ||= user.find_by(token: token) if token
  end

  def check_user_auth
    user = current_user
    redirect_to '/login', alert: 'Debe iniciar session acceder al sistema' unless @current_user.present?
  end

  def get_menu_original
    menu = {}


    menu['Apis'] = {}
    menu['Apis']['id'] = { 'id' => 9, 'activo' => false, 'tipo' => 'ADM', 'visible' => true }
    menu['Apis']['menu'] = []
    menu['Apis']['menu'] << { 'id' => 91, 'activo' => false, 'nombre' => 'Monitoreo',
                                  'path' => '/unica/retirados/retirados_pendiente', 'tipo' => 'ADM', 'visible' => true }


    menu['Mantenimiento'] = {}
    menu['Mantenimiento']['id'] = { 'id' => 1, 'activo' => false, 'tipo' => 'ADM/GRP/INT/COB', 'visible' => true }
    menu['Mantenimiento']['menu'] = []
    menu['Mantenimiento']['menu'] << { 'id' => 11, 'activo' => false, 'nombre' => 'Cuentas Bancarias',
                                       'path' => '/cuentas_banca', 'tipo' => 'ADM/GRP/COB', 'visible' => true }
    # menu['Mantenimiento']['menu'] << { 'id' => 12, 'activo' => false, 'nombre' => 'Modificar Tasa Cambio', 'path' => '/factor_cambio',
    #                                    'tipo' => 'ADM/GRP', 'visible' => false }
    # menu['Mantenimiento']['menu'] << { 'id' => 16, 'activo' => false, 'nombre' => 'Consultar Tasa Cambio', 'path' => '/factor_cambio/consulta',
    #                                    'tipo' => 'ADM/GRP', 'visible' => false }
    menu['Mantenimiento']['menu'] << { 'id' => 15, 'activo' => false, 'nombre' => 'Tasa Cambio Agentes', 'path' => '/tasas_cambio',
                                       'tipo' => 'GRP', 'visible' => true }
    menu['Mantenimiento']['menu'] << { 'id' => 13, 'activo' => false, 'nombre' => 'Usuarios', 'path' => '/usuarios',
                                       'tipo' => 'ADM/INT/GRP', 'visible' => true }
    menu['Mantenimiento']['menu'] << { 'id' => 14, 'activo' => false, 'nombre' => 'Revisar Tareas', 'path' => '/sidekiq',
                                       'tipo' => 'ADM', 'visible' => true }
    menu['Mantenimiento']['menu'] << { 'id' => 15, 'activo' => false, 'nombre' => 'Urls', 'path' => '/bases_urls',
                                       'tipo' => 'ADM', 'visible' => true }


    menu['Administracion'] = {}
    menu['Administracion']['id'] = { 'id' => 2, 'activo' => false, 'tipo' => 'ADM/GRP/INT/COB', 'visible' => true }
    menu['Administracion']['menu'] = []
    menu['Administracion']['menu'] << { 'id' => 20, 'activo' => false, 'nombre' => 'Intermediarios',
                                        'path' => '/intermediarios', 'tipo' => 'ADM', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 21, 'activo' => false, 'nombre' => 'Grupos', 'path' => '/grupos',
                                        'tipo' => 'ADM/INT', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 22, 'activo' => false, 'nombre' => 'Agentes', 'path' => '/agentes',
                                        'tipo' => 'GRP', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 23, 'activo' => false, 'nombre' => 'Clientes', 'path' => '/taquillas',
                                        'tipo' => 'ADM/GRP/COB', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 24, 'activo' => false, 'nombre' => 'Integradores', 'path' => '/integradores',
                                        'tipo' => 'ADM', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 25, 'activo' => false, 'nombre' => 'Bloqueo Masivo',
                                        'path' => '/configuracion/masivo', 'tipo' => 'ADM', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 26, 'activo' => false, 'nombre' => 'Solicitudes-recargas',
                                        'path' => '/solicitudes/recargas', 'tipo' => 'GRP/COB', 'visible' => false }
    menu['Administracion']['menu'] << { 'id' => 27, 'activo' => false, 'nombre' => 'Solicitudes-retiros',
                                        'path' => '/solicitudes/retiros', 'tipo' => 'GRP/COB', 'visible' => false }
    menu['Administracion']['menu'] << { 'id' => 28, 'activo' => false, 'nombre' => 'Monitor de Propuestas',
                                        'path' => '/home/pizarra_propuestas', 'tipo' => 'ADM', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 29, 'activo' => false, 'nombre' => 'Chats',
                                        'path' => '/unica/chats', 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Administracion']['menu'] << { 'id' => 291, 'activo' => false, 'nombre' => 'Ajustes Clientes',
                                        'path' => '/cajero_taquilla', 'tipo' => 'COB', 'visible' => true }

    menu['Caballos'] = {}
    menu['Caballos']['id'] = { 'id' => 6, 'activo' => false, 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Caballos']['menu'] = []
    menu['Caballos']['menu'] << { 'id' => 61, 'activo' => false, 'nombre' => 'Hipodromos', 'path' => '/hipodromos',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 62, 'activo' => false, 'nombre' => 'Jornadas', 'path' => '/jornadas',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 63, 'activo' => false, 'nombre' => 'Carreras', 'path' => '/carreras',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 601, 'activo' => false, 'nombre' => 'Post Time',
                                  'path' => '/unica/configuracion/posttime', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 602, 'activo' => false, 'nombre' => 'Retirar Caballo',
                                  'path' => '/unica/retirados/index', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 603, 'activo' => false, 'nombre' => 'Premiacion',
                                  'path' => '/unica/premiacion_puestos', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 67, 'activo' => false, 'nombre' => 'Premios Ingresados',
                                  'path' => '/reportes/premios_ingresados_index', 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 68, 'activo' => false, 'nombre' => 'Carreras/Llaves',
                                  'path' => '/carreras/consultar_llaves', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 691, 'activo' => false, 'nombre' => 'Videos Taquilla',
                                  'path' => '/unica/utilidades/videos', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 692, 'activo' => false, 'nombre' => 'Retrospectos',
                                  'path' => '/unica/utilidades/prospectos', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 693, 'activo' => false, 'nombre' => 'Suspender Carrera',
                                  'path' => '/unica/carreras/suspender', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 694, 'activo' => false, 'nombre' => 'Generar Propuestas',
                                  'path' => '/unica/propuestas_caballos', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 695, 'activo' => false, 'nombre' => 'Cierre M/Multiple',
                                  'path' => '/unica/configuracion/cierre_manual', 'tipo' => 'ADM', 'visible' => true }
    menu['Caballos']['menu'] << { 'id' => 696, 'activo' => false, 'nombre' => 'Envios Masivos',
                                  'path' => '/unica/envios_masivos', 'tipo' => 'ADM', 'visible' => true }

    menu['Tablas'] = {}
    menu['Tablas']['id'] = { 'id' => 7, 'activo' => false, 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Tablas']['menu'] = []
    menu['Tablas']['menu'] << { 'id' => 71, 'activo' => false, 'nombre' => 'Cargar Tablas', 'path' => '/tablas',
                                'tipo' => 'ADM/GRP', 'visible' => true }

    menu['Deportes'] = {}
    menu['Deportes']['id'] = { 'id' => 3, 'activo' => false, 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Deportes']['menu'] = []
    menu['Deportes']['menu'] << { 'id' => 31, 'activo' => false, 'nombre' => 'Deportes', 'path' => '/juegos',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 32, 'activo' => false, 'nombre' => 'Ligas', 'path' => '/ligas', 'tipo' => 'ADM',
                                  'visible' => true }
    #  menu['Deportes']['menu'] << {"id" => 33,"activo" => false,"nombre" => "Equipos","path" => "/equipos", "tipo" => "ADM", "visible" => true}
    menu['Deportes']['menu'] << { 'id' => 34, 'activo' => false, 'nombre' => 'Juegos (Match)', 'path' => '/matchs',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 35, 'activo' => false, 'nombre' => 'Premiar',
                                  'path' => '/unica/premiacion_deportes', 'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 36, 'activo' => false, 'nombre' => 'Premios Ingresados',
                                  'path' => '/reportes/premios_ingresados_deportes', 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 37, 'activo' => false, 'nombre' => 'Cambiar Nombre(Eq)',
                                  'path' => '/unica/utilidades/cambiar_nombre_equipos', 'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 38, 'activo' => false, 'nombre' => 'Estado Matchs',
                                  'path' => '/unica/deportes/utilidades/verificar_deportes', 'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 39, 'activo' => false, 'nombre' => 'Parametros G.Propuestas',
                                  'path' => '/unica/generador_propuestas', 'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 301, 'activo' => false, 'nombre' => 'Montos G.Propuestas',
                                  'path' => '/unica/configuracion/montos_propuestas_deportes', 'tipo' => 'ADM', 'visible' => true }
    menu['Deportes']['menu'] << { 'id' => 302, 'activo' => false, 'nombre' => 'Usuarios G.Propuestas',
                                  'path' => '/unica/configuracion/usuarios_generador', 'tipo' => 'ADM', 'visible' => true }
    menu['Configuracion'] = {}
    menu['Configuracion']['id'] = { 'id' => 4, 'activo' => false, 'tipo' => 'ADM/GRP', 'visible' => true }
    menu['Configuracion']['menu'] = []
    menu['Configuracion']['menu'] << { 'id' => 41, 'activo' => false, 'nombre' => 'Reglas Taquilla',
                                       'path' => '/configuracion/reglas', 'tipo' => 'ADM', 'visible' => true }
    menu['Configuracion']['menu'] << { 'id' => 42, 'activo' => false, 'nombre' => 'Mensaje Taquillas',
                                       'path' => '/configuracion/mensajes_taquilla', 'tipo' => 'ADM', 'visible' => true }
    menu['Configuracion']['menu'] << { 'id' => 43, 'activo' => false, 'nombre' => 'Tasa de Cambio API',
                                       'path' => '/unica/utilidades/exchange_rates', 'tipo' => 'GRP', 'visible' => true }

    menu['Reportes'] = {}
    menu['Reportes']['id'] = { 'id' => 5, 'activo' => false, 'tipo' => 'ADM/GRP/INT/COB', 'visible' => true }
    menu['Reportes']['menu'] = []
    menu['Reportes']['menu'] << { 'id' => 51, 'activo' => false, 'nombre' => 'Cuadre General',
                                  'path' => '/reportes/cuadre_general_caballos', 'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 52, 'activo' => false, 'nombre' => 'Post Time', 'path' => '/reportes/posttime',
                                  'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 53, 'activo' => false, 'nombre' => 'Solicitudes',
                                  'path' => '/reportes/solicitudes', 'tipo' => 'COB', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 54, 'activo' => false, 'nombre' => 'Movimientos Usuarios',
                                  'path' => '/unica/reportes/movimientos', 'tipo' => 'GRP/COB', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 55, 'activo' => false, 'nombre' => 'Cuadre Mensual',
                                  'path' => '/unica/reportes/cuadre_mensual', 'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 568, 'activo' => false, 'nombre' => 'Cuadre Paginas',
                                  'path' => '/unica/reportes/cuadre_paginas', 'tipo' => 'ADM', 'visible' => true }

                                  
    # menu['Reportes']['menu'] << { 'id' => 58, 'activo' => false, 'nombre' => 'Historial Tasas',
    #                               'path' => '/reportes/historial_tasa', 'tipo' => 'GRP', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 581, 'activo' => false, 'nombre' => 'Historial Tasas Grupo',
                                  'path' => '/reportes/historial_tasa_grupo', 'tipo' => 'GRP', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 59, 'activo' => false, 'nombre' => 'Carreras Cerradas',
                                  'path' => '/reportes/carreras_cerradas', 'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 56, 'activo' => false, 'nombre' => 'Envios Cajero Externo',
                                  'path' => '/reportes/pases_cajero_externo', 'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 502, 'activo' => false, 'nombre' => 'Relacion de tickets',
                                  'path' => '/unica/reportes/relacion_tickets', 'tipo' => 'ADM/GRP/COB', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 503, 'activo' => false, 'nombre' => 'Cuadre General Agentes Ext',
                                  'path' => '/unica/reportes/cuadre_general_externo', 'tipo' => 'GRP/COB', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 504, 'activo' => false, 'nombre' => 'Chats en Observación',
                                  'path' => '/unica/chats/chats_devueltos', 'tipo' => 'GRP/ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 505, 'activo' => false, 'nombre' => 'Movimiento de Cajero',
                                  'path' => '/solicitudes/movimiento_cajero', 'tipo' => 'COB', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 506, 'activo' => false, 'nombre' => 'Jugadas Pendientes',
                                  'path' => '/reportes/jugadas_pendientes', 'tipo' => 'ADM', 'visible' => true }
    menu['Reportes']['menu'] << { 'id' => 507, 'activo' => false, 'nombre' => 'Auditoria de clientes',
                                  'path' => '/unica/utilidades/search_user', 'tipo' => 'ADM/GRP', 'visible' => true }

                                  
    menu['Atajos'] = {}
    menu['Atajos']['id'] = { 'id' => 8, 'activo' => false, 'tipo' => 'ADM', 'visible' => true }
    menu['Atajos']['menu'] = []
    menu['Atajos']['menu'] << { 'id' => 81, 'activo' => false, 'nombre' => 'Activar Api',
                                'path' => '/unica/atajos/activar_api', 'tipo' => 'ADM', 'visible' => true }
    menu['Atajos']['menu'] << { 'id' => 82, 'activo' => false, 'nombre' => 'Administrar Cierre Api',
                                'path' => '/cierres_api', 'tipo' => 'ADM', 'visible' => true }

    menu
  end
end
