require 'sidekiq/web'

Rails.application.routes.draw do
  #  if session[:usuario_actual]['tipo'] == 'ADM'
  mount Sidekiq::Web => '/sidekiq'
  #  end

  root to: 'login#index'
  # health_check_routes
  mount HealthMonitor::Engine, at: '/'

  post '/proxy/request_proxy', to: 'proxy#request_proxy'
  post '/proxy_royal', to: 'proxy#proxy_royal' 
  post '/proxy_inmejorable', to: 'proxy_inmejorable#proxy_caballos' 

  resources :bases_urls
  post '/bases_urls/update', to: 'bases_urls#update'
  resources :login, only: %i[index create destroy]
  post '/home/actualizar_datos', to: 'home#actualizar_datos'
  get '/home/pizarra_propuestas', to: 'home#pizarra_propuestas'
  resources :home, only: [:index]
  resources :hipodromos
  post '/jornadas/eliminar_jornada', to: 'jornadas#eliminar_jornada'
  resources :factor_cambio
  post '/factor_cambio/create', to: 'factor_cambio#create'
  get '/factor_cambio/consulta', to: 'factor_cambio#consulta'
  resources :tasas_cambio
  post '/tasas_cambio/create', to: 'tasas_cambio#create'
  get '/tasas_cambio/edit_by_group', to: 'tasas_cambio#edit_by_group'
  post '/tasas_cambio/por_agentes', to: 'tasas_cambio#por_agentes'

  resources :jornadas
  resources :juegos
  resources :ligas
  post '/equipos/buscar_liga', to: 'equipos#buscar_liga'
  resources :equipos
  resources :matchs
  post '/matchs/buscar_liga', to: 'matchs#buscar_liga'
  post '/matchs/cerrar_match', to: 'matchs#cerrar_match'

  resources :integradores
  post '/carreras/detalle', to: 'carreras#detalle'
  get '/carreras/consultar_llaves', to: 'carreras#consultar_llaves'
  resources :carreras
  get '/retirados/retirados_pendiente', to: 'retirados#retirados_pendiente'
  post '/retirados/retirar_pendientes', to: 'retirados#retirar_pendientes'
  resources :retirados
  resources :grupos
  resources :intermediarios
  resources :cobradores, path: '/agentes'

  # get '/agentes', to: 'cobradores#index'
  # get '/agentes/show', to: 'cobradores#show'

  resources :taquillas
  resources :cajero_taquilla
  resources :taquilla_grupos
  resources :premiar
  post '/usuarios/buscar_tipo', to: 'usuarios#buscar_tipo'
  resources :usuarios
  resources :cuentas_banca
  get '/solicitudes/movimiento_cajero', to: 'solicitudes#movimiento_cajero'
  post '/solicitudes/movimiento_cajero_reporte', to: 'solicitudes#movimiento_cajero_reporte'
  post '/retirados/crear_caballos', to: 'retirados#crear_caballos'
  post '/retirados/retirar', to: 'retirados#retirar'
  get '/configuracion/posttime', to: 'configuracion#posttime'
  get '/configuracion/reglas', to: 'configuracion#reglas'
  post '/configuracion/grabar_reglas', to: 'configuracion#grabar_reglas'
  post '/configuracion/buscar_carrera', to: 'configuracion#buscar_carrera'
  post '/configuracion/buscar_carrera2', to: 'configuracion#buscar_carrera2'
  post '/configuracion/cambiar_hora', to: 'configuracion#cambiar_hora'
  post '/configuracion/cerrar_carrera', to: 'configuracion#cerrar_carrera'
  post '/cuentas_banca/create', to: 'cuentas_banca#create'
  post '/taquillas/validar_correo', to: 'taquillas#validar_correo'
  # post '/taquillas_grupo/create', to:'taquillas_grupo#create'
  get '/solicitudes/recargas', to: 'solicitudes#recargas'
  get '/solicitudes/retiros', to: 'solicitudes#retiros'
  post '/solicitudes/verificar_recarga', to: 'solicitudes#verificar_recarga'
  post '/solicitudes/procesar_recarga', to: 'solicitudes#procesar_recarga'
  post '/solicitudes/procesar_retiro', to: 'solicitudes#procesar_retiro'

  post '/carreras/buscar_jornadas', to: 'carreras#buscar_jornadas'
  post '/carreras/buscar_carreras', to: 'carreras#buscar_carreras'
  post '/carreras/buscar_caballos', to: 'carreras#buscar_caballos'
  post '/carreras/crear_caballos', to: 'carreras#crear_caballos'
  post '/carreras/crear_caballos2', to: 'carreras#crear_caballos2'
  post '/carreras/crear_final_carrera', to: 'carreras#crear_final_carrera'
  post '/login/desloguear_taquilla', to: 'login#desloguear_taquilla'
  post '/taquillas/buscar_por_grupo', to: 'taquillas#buscar_por_grupo'
  post '/premiar/buscar_jornadas', to: 'premiar#buscar_jornadas'
  post '/premiar/buscar_caballos', to: 'premiar#buscar_caballos'
  post '/premiar/crear_caballos', to: 'premiar#crear_caballos'
  post '/premiar/premiar', to: 'premiar#premiar'
  get '/reportes/cuadre_general', to: 'reportes#cuadre_general'
  post '/reportes/cuadre_general_por_grupo', to: 'reportes#cuadre_general_por_grupo'
  get '/reportes/cuadre_general_caballos', to: 'reportes#cuadre_general_caballos'
  post '/reportes/cuadre_general_por_grupo_caballos', to: 'reportes#cuadre_general_por_grupo_caballos'
  get '/reportes/cuadre_general_por_grupo_caballos', to: 'reportes#cuadre_general_por_grupo_caballos'
  get '/reportes/cuadre_general_cobradores', to: 'reportes#cuadre_general_cobradores'
  post '/reportes/cuadre_general_por_grupo_cobradores', to: 'reportes#cuadre_general_por_grupo_cobradores'
  get '/reportes/cuadre_general_por_grupo_cobradores', to: 'reportes#cuadre_general_por_grupo_cobradores'

  get '/reportes/premios_ingresados_index', to: 'reportes#premios_ingresados_index'
  post '/reportes/premios_ingresados', to: 'reportes#premios_ingresados'
  get '/reportes/posttime', to: 'reportes#posttime'
  post '/reportes/posttime_consulta', to: 'reportes#posttime_consulta'
  get '/reportes/solicitudes', to: 'reportes#solicitudes'
  get '/reportes/movimientos', to: 'reportes#movimientos'
  post '/reportes/solicitudes', to: 'reportes#solicitudes_filtradas'
  post '/solicitudes/mostrar_imagen', to: 'solicitudes#mostrar_imagen'
  post '/solicitudes/verificar_retiro', to: 'solicitudes#verificar_retiro'
  post '/solicitudes/revisar_solicitudes_pendientes', to: 'solicitudes#revisar_solicitudes_pendientes'
  post '/solicitudes/get_solicitudes_pendientes', to: 'solicitudes#get_solicitudes_pendientes'
  get '/solicitudes/ajustar_saldos', to: 'solicitudes#ajustar_saldos'
  post '/solicitudes/ajustar_monto', to: 'solicitudes#ajustar_monto'

  get '/solicitudes/ajustar_saldos', to: 'solicitudes#ajustar_saldos'
  post '/retirados/buscar_carreras', to: 'retirados#buscar_carreras'
  get '/configuracion/masivo', to: 'configuracion#masivo'
  post '/configuracion/bloqueo_masivo', to: 'configuracion#bloqueo_masivo'
  post '/reportes/movimientos_taquilla', to: 'reportes#movimientos_taquilla'

  get '/reportes/cuadre_general_grupo', to: 'reportes#cuadre_general_grupo'
  post '/reportes/cuadre_general_grupo2', to: 'reportes#cuadre_general_grupo2'

  get '/deportes/premiar', to: 'deportes#premiar'
  post '/deportes/buscar_deportes', to: 'deportes#buscar_deportes'
  post '/deportes/buscar_ligas', to: 'deportes#buscar_ligas'
  post '/deportes/buscar_matchs', to: 'deportes#buscar_matchs'
  post '/deportes/buscar_juego', to: 'deportes#buscar_juego'
  post '/deportes/premiar_juego', to: 'deportes#premiar_juego'
  post '/solicitudes/verificar_tasa', to: 'solicitudes#verificar_tasa'
  get  '/reportes/historial_tasa', to: 'reportes#historial_tasa'
  post '/reportes/historial_tasas', to: 'reportes#historial_tasas'
  get  '/reportes/historial_tasa_grupo', to: 'reportes#historial_tasa_grupo'
  post '/reportes/historial_tasas_grupo', to: 'reportes#historial_tasas_grupo'

  get  '/reportes/carreras_cerradas', to: 'reportes#carreras_cerradas'
  post '/reportes/carreras_cerradas_fecha', to: 'reportes#carreras_cerradas_fecha'

  get '/reportes/premios_ingresados_deportes', to: 'reportes#premios_ingresados_deportes'
  post '/reportes/premios_ingresados_ingresados_consulta', to: 'reportes#premios_ingresados_ingresados_consulta'
  get '/reportes/pases_cajero_externo', to: 'reportes#pases_cajero_externo'
  post '/reportes/buscar_carreras_cerradas_fecha', to: 'reportes#buscar_carreras_cerradas_fecha'
  post '/reportes/consultar_pase_cajero_externo', to: 'reportes#consultar_pase_cajero_externo'
  get '/reportes/cuadre_general_externo', to: 'reportes#cuadre_general_externo'
  post '/reportes/cuadre_general_por_agentes_externo', to: 'reportes#cuadre_general_por_agentes_externo'
  get '/reportes/cuadre_general_por_agentes_externo', to: 'reportes#cuadre_general_por_agentes_externo'

  get '/reportes/cuadre_general_externo_general', to: 'reportes#cuadre_general_externo_general'
  post '/reportes/cuadre_general_por_agentes_externo_general',
       to: 'reportes#cuadre_general_por_agentes_externo_general'
  get '/reportes/cuadre_general_por_agentes_externo_general',
      to: 'reportes#cuadre_general_por_agentes_externo_general'
  get '/reportes/relacion_tickets', to: 'reportes#relacion_tickets'
  post '/reportes/relacion_tickets_detalle', to: 'reportes#relacion_tickets_detalle'
  get '/reportes/jugadas_pendientes', to: 'reportes#jugadas_pendientes'
  post '/reportes/buscar_jugadas_pendientes', to: 'reportes#buscar_jugadas_pendientes'


  get '/tablas', to: 'tablas#index'
  post '/tablas/buscar_carreras', to: 'tablas#buscar_carreras'
  post '/tablas/crear_caballos', to: 'tablas#crear_caballos'
  post '/tablas/procesar_carga', to: 'tablas#procesar_carga'
  post '/api/get_currencys', to: 'api#get_currencys'
  post '/api/update_exchange_rate', to: 'api#update_exchange_rate'
  post '/api/get_config', to: 'api#get_config'
  post '/api/set_config', to: 'api#set_config'
  post '/api/award_race', to: 'unica/api#award_race'
  post '/api/post_time', to: 'unica/api#post_time'
  post '/api/retirar_interno', to: 'unica/api#retirar_interno'
  post '/api/premiar_interno', to: 'unica/api#premiar_interno'
  post '/api/invalidate_horse', to: 'unica/api#invalidate_horse'
  post '/api/close_race', to: 'unica/api#close_race'
  post '/api/cierre_carrera_interno', to: 'unica/api#cierre_carrera_interno'
  post '/api/activate_horse', to: 'unica/api#activate_horse'
  post '/api/operations_failds', to: 'api#operations_failds'
  post '/api/set_max_min', to: 'api#set_max_min'
  get '/premiar/premiar_proxima_api', to: 'premiar#premiar_proxima_api'
  post '/ligas/filtrar', to: 'ligas#filtrar'
  post '/ligas/filtrar', to: 'hipodromos#filtrar'
  post '/api/generate_demo', to: 'api#generate_demo'
  post 'hipodromos/filtrar', to: 'hipodromos#filtrar'
  get '/:cierre_api', to: 'hipodromos#cierre_api'
  post '/hipodromos/update_cierres', to: 'hipodromos#update_cierres'
  post '/reportes/cuadre_general_api', to: 'unica/reportes#cuadre_general_api'

  post '/querys/ticket', to: 'unica/querys#relacion_tickets_detalle'

  ## unica
  namespace :unica do
    get '/envios_masivos', to: 'envios_masivos#index'
    post '/envios_masivos/enviar', to: 'envios_masivos#enviar'
    post '/envios_masivos/search_data', to: 'envios_masivos#search_data'
    namespace :deportes do
      get '/utilidades/verificar_deportes', to: 'utilidades#verificar_deportes'
    end
    resources :generador_propuestas
    post '/generador_propuestas/save_parameters', to: 'generador_propuestas#save_parameters'
    post '/generador_propuestas/usuarios', to: 'generador_propuestas#usuarios'
    post '/generador_propuestas/save_users', to: 'generador_propuestas#save_users'
    get '/chats', to: 'chats#index'
    post '/chats_all', to: 'chats#chats_all'
    post '/chats/remove_item', to: 'chats#remove_item'
    post '/chats/send_item', to: 'chats#send_item'
    get '/chats/chats_devueltos', to: 'chats#chats_devueltos'
    post '/chats/en_observacion', to: 'chats#en_observacion'
    resources :premiacion_puestos
    get '/atajos/activar_api', to: 'atajos#activar_api'
    post '/atajos/activar_cierre_api', to: 'atajos#activar_cierre_api'

    get '/premiacion_puestos', to: 'premiacion_puestos#index'
    post '/premiacion_puestos/buscar_jornadas', to: 'premiacion_puestos#buscar_jornadas'
    post '/premiacion_puestos/buscar_caballos', to: 'premiacion_puestos#buscar_caballos'
    post '/premiacion_puestos/crear_caballos', to: 'premiacion_puestos#crear_caballos'
    post '/premiacion_puestos/premiar_puestos', to: 'premiacion_puestos#premiar_puestos'
    post '/premiacion_puestos/premiar_manual', to: 'premiacion_puestos#premiar_manual'

    get '/configuracion/obtener_datos_postime', to: 'configuracion#obtener_datos_postime'
    get '/configuracion/posttime', to: 'configuracion#posttime'
    post '/configuracion/buscar_carrera', to: 'configuracion#buscar_carrera'
    post '/configuracion/buscar_carrera2', to: 'configuracion#buscar_carrera2'
    post '/configuracion/cambiar_hora', to: 'configuracion#cambiar_hora'
    post '/configuracion/cerrar_carrera', to: 'configuracion#cerrar_carrera'
    post '/configuracion/cerrar_carrera_manual', to: 'configuracion#cerrar_carrera_manual'
    post '/configuracion/cuadrar_carrera', to: 'configuracion#cuadrar_carrera'
    get '/configuracion/usuarios_generador', to: 'configuracion#usuarios_generador'
    get '/configuracion/montos_propuestas_deportes', to: 'configuracion#montos_propuestas_deportes'
    post '/configuracion/grabar_montos_propuestas_deportes', to: 'configuracion#grabar_montos_propuestas_deportes'
    get '/configuracion/cierre_manual', to: 'configuracion#cierre_manual'
    post '/premiacion_puestos/buscar_proxima_hip', to: 'premiacion_puestos#buscar_proxima_hip'

    get '/retirados/retirados_pendiente', to: 'retirados#retirados_pendiente'
    post '/retirados/retirar_pendientes', to: 'retirados#retirar_pendientes'
    get '/retirados/index', to: 'retirados#index'
    post '/retirados/crear_caballos', to: 'retirados#crear_caballos'
    post '/retirados/retirar', to: 'retirados#retirar'
    post 'retirados/buscar_carreras', to: 'retirados#buscar_carreras'
    post '/retirados/retirar_manual', to: 'retirados#retirar_manual'

    get '/reportes/cuadre_general_externo', to: 'reportes#cuadre_general_externo'
    post '/reportes/cuadre_general_por_agentes_externo', to: 'reportes#cuadre_general_por_agentes_externo'
    get '/reportes/cuadre_general_por_agentes_externo', to: 'reportes#cuadre_general_por_agentes_externo'

    get '/reportes/relacion_tickets', to: 'reportes#relacion_tickets'
    post '/reportes/relacion_tickets_detalle', to: 'reportes#relacion_tickets_detalle'
    post '/querys/ticket', to: 'querys#relacion_tickets_detalle'
    get '/reportes/cuadre_mensual', to: 'reportes#cuadre_mensual'
    post '/reportes/cuadre_mensual_grupo', to: 'reportes#cuadre_mensual_grupo'
    get '/reportes/cuadre_paginas', to: 'reportes#cuadre_paginas'
    post '/reportes/cuadre_paginas_grupo', to: 'reportes#cuadre_paginas_grupo'
    get '/reportes/cuadre_general_caballos', to: 'reportes#cuadre_general_caballos'
    post '/reportes/cuadre_general_por_grupo_caballos', to: 'reportes#cuadre_general_por_grupo_caballos'
    get '/reportes/cuadre_general_por_grupo_caballos', to: 'reportes#cuadre_general_por_grupo_caballos'
    get '/reportes/cuadre_general_cobradores', to: 'reportes#cuadre_general_cobradores'
    post '/reportes/cuadre_general_por_grupo_cobradores', to: 'reportes#cuadre_general_por_grupo_cobradores'
    get '/reportes/cuadre_general_por_grupo_cobradores', to: 'reportes#cuadre_general_por_grupo_cobradores'
    post '/reportes/movimientos_taquilla', to: 'reportes#movimientos_taquilla'
    get '/reportes/movimientos', to: 'reportes#movimientos'
    get '/reportes/jugadas_taquilla', to: 'reportes#jugadas_taquilla'
    post '/reportes/jugadas_taquilla2', to: 'reportes#jugadas_taquilla2'
    post '/reportes/buscar_tickets_detalle', to: 'reportes#buscar_tickets_detalle'

    get '/premiacion_deportes', to: 'premiacion_deportes#index'
    post '/premiacion_deportes/buscar_deportes', to: 'premiacion_deportes#buscar_deportes'
    post '/premiacion_deportes/buscar_ligas', to: 'premiacion_deportes#buscar_ligas'
    post '/premiacion_deportes/buscar_matchs', to: 'premiacion_deportes#buscar_matchs'
    post '/premiacion_deportes/buscar_juego', to: 'premiacion_deportes#buscar_juego'
    post '/premiacion_deportes/premiar_juego', to: 'premiacion_deportes#premiar_juego'

    get '/utilidades/cambiar_nombre_equipos', to: 'utilidades#cambiar_nombre_equipos'
    post '/utilidades/buscar_ligas', to: 'utilidades#buscar_ligas'
    post '/utilidades/buscar_equipos', to: 'utilidades#buscar_equipos'
    post '/utilidades/cambiar_nombre_ind', to: 'utilidades#cambiar_nombre_ind'
    post '/utilidades/refrescar_ligas', to: 'utilidades#refrescar_ligas'
    get '/utilidades/videos', to: 'utilidades#videos'
    post '/utilidades/cambiar_ruta_video', to: 'utilidades#cambiar_ruta_video'
    post '/utilidades/preview_video', to: 'utilidades#preview_video'
    get '/utilidades/prospectos', to: 'utilidades#prospectos'
    post '/utilidades/cambiar_ruta_prospectos', to: 'utilidades#cambiar_ruta_prospectos'
    get '/carreras/buscar_carreras', to: 'carreras#buscar_carreras'
    get 'carreras/suspender', to: 'carreras#suspender'
    post '/carreras/buscar_jornadas', to: 'carreras#buscar_jornadas'
    post '/carreras/buscar_carreras', to: 'carreras#buscar_carreras'
    post '/carreras/buscar_caballos', to: 'carreras#buscar_caballos'
    post 'carreras/crear_caballos', to: 'carreras#crear_caballos'
    post 'carreras/suspender_carrera', to: 'carreras#suspender_carrera'
    get '/utilidades/exchange_rates', to: 'utilidades#exchange_rates'
    get '/utilidades/search_user', to: 'utilidades#search_user'
    post '/utilidades/examinar_usuario', to: 'utilidades#examinar_usuario'
    post '/utilidades/auditoria', to: 'utilidades#auditoria'

    # propuestas
    get '/propuestas_caballos', to: 'propuestas_caballos#index'
    post '/propuestas_caballos/crear_caballos', to: 'propuestas_caballos#crear_caballos'
    post 'propuestas_caballos/crear_propuestas', to: 'propuestas_caballos#crear_propuestas'

  end

  mount ActionCable.server => '/cable'
end
