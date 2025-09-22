# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_06_24_132801) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apps", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "bancos", force: :cascade do |t|
    t.string "banco_id"
    t.string "nombre"
    t.integer "moneda"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "grupo_id", default: 0
  end

  create_table "bancos_clientes", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.string "banco_id"
    t.string "nombre"
    t.integer "tipo_cuenta"
    t.string "nombre_cliente"
    t.string "cedula_cliente"
    t.string "telefono"
    t.string "email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["usuarios_taquilla_id"], name: "index_bancos_clientes_on_usuarios_taquilla_id"
  end

  create_table "base_urls", force: :cascade do |t|
    t.string "gticket"
    t.string "pendientes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bloqueo_masivos", force: :cascade do |t|
    t.boolean "activo", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "caballos_carreras", id: :serial, force: :cascade do |t|
    t.integer "carrera_id"
    t.string "nombre"
    t.boolean "retirado", default: false
    t.float "peso", default: 0.0
    t.string "jinete", default: ""
    t.string "numero_puesto"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "ml", default: ""
    t.float "o", default: 0.0
    t.integer "us", default: 0
    t.string "entrenador"
    t.string "id_api"
    t.index ["carrera_id"], name: "index_caballos_carreras_on_carrera_id"
  end

  create_table "caballos_retirados_confirmacions", force: :cascade do |t|
    t.bigint "hipodromo_id"
    t.bigint "carrera_id"
    t.bigint "caballos_carrera_id"
    t.integer "status"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["caballos_carrera_id"], name: "index_caballos_retirados_confirmacions_on_caballos_carrera_id"
    t.index ["carrera_id"], name: "index_caballos_retirados_confirmacions_on_carrera_id"
    t.index ["hipodromo_id"], name: "index_caballos_retirados_confirmacions_on_hipodromo_id"
    t.index ["user_id"], name: "index_caballos_retirados_confirmacions_on_user_id"
  end

  create_table "carreras", id: :serial, force: :cascade do |t|
    t.integer "jornada_id"
    t.string "hora_carrera"
    t.string "numero_carrera"
    t.integer "cantidad_caballos"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "hora_pautada"
    t.string "utc"
    t.string "distance"
    t.string "name"
    t.string "purse"
    t.jsonb "results"
    t.string "id_api"
    t.integer "hipodromo_id"
    t.string "hipodromo_name"
    t.index ["jornada_id"], name: "index_carreras_on_jornada_id"
  end

  create_table "carreras_ids_nyras", force: :cascade do |t|
    t.string "codigo_nyra"
    t.jsonb "ids_carrera"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "carreras_p_logros", force: :cascade do |t|
    t.bigint "premios_ingresado_id"
    t.bigint "carrera_id"
    t.bigint "usuarios_taquilla_id"
    t.bigint "operaciones_cajero_id"
    t.bigint "propuestas_caballo_id"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_carreras_p_logros_on_carrera_id"
    t.index ["operaciones_cajero_id"], name: "index_carreras_p_logros_on_operaciones_cajero_id"
    t.index ["premios_ingresado_id"], name: "index_carreras_p_logros_on_premios_ingresado_id"
    t.index ["propuestas_caballo_id"], name: "index_carreras_p_logros_on_propuestas_caballo_id"
    t.index ["usuarios_taquilla_id"], name: "index_carreras_p_logros_on_usuarios_taquilla_id"
  end

  create_table "carreras_p_puestos", force: :cascade do |t|
    t.bigint "premios_ingresado_id"
    t.bigint "carrera_id"
    t.bigint "usuarios_taquilla_id"
    t.bigint "operaciones_cajero_id"
    t.bigint "propuestas_caballos_puesto_id"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_carreras_p_puestos_on_carrera_id"
    t.index ["operaciones_cajero_id"], name: "index_carreras_p_puestos_on_operaciones_cajero_id"
    t.index ["premios_ingresado_id"], name: "index_carreras_p_puestos_on_premios_ingresado_id"
    t.index ["propuestas_caballos_puesto_id"], name: "index_carreras_p_puestos_on_propuestas_caballos_puesto_id"
    t.index ["usuarios_taquilla_id"], name: "index_carreras_p_puestos_on_usuarios_taquilla_id"
  end

  create_table "carreras_premiadas", force: :cascade do |t|
    t.bigint "premios_ingresado_id"
    t.bigint "carrera_id"
    t.bigint "usuarios_taquilla_id"
    t.bigint "operaciones_cajero_id"
    t.bigint "enjuego_id"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_carreras_premiadas_on_carrera_id"
    t.index ["enjuego_id"], name: "index_carreras_premiadas_on_enjuego_id"
    t.index ["operaciones_cajero_id"], name: "index_carreras_premiadas_on_operaciones_cajero_id"
    t.index ["premios_ingresado_id"], name: "index_carreras_premiadas_on_premios_ingresado_id"
    t.index ["usuarios_taquilla_id"], name: "index_carreras_premiadas_on_usuarios_taquilla_id"
  end

  create_table "chats", force: :cascade do |t|
    t.integer "grupo_id"
    t.jsonb "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "delivered", default: false
    t.boolean "for_all", default: false
    t.boolean "removed", default: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "cierre_carreras", force: :cascade do |t|
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cierre_logs", force: :cascade do |t|
    t.text "parametros"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cierres_apis", force: :cascade do |t|
    t.boolean "es_api"
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "clientes", id: :serial, force: :cascade do |t|
    t.string "cedula"
    t.string "nombre"
    t.string "telefono"
    t.string "direccion"
    t.string "correo"
    t.boolean "activo", default: true
    t.integer "status", default: 0
    t.float "saldo", default: 0.0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cobradores", force: :cascade do |t|
    t.string "nombre"
    t.string "apellido"
    t.string "correo"
    t.string "telefono"
    t.bigint "grupo_id"
    t.text "usuarios_taquilla_id"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "integrador_id"
    t.float "comision_banca", default: 0.0
    t.float "comision_integrador", default: 0.0
    t.float "comision_grupo", default: 0.0
    t.bigint "moneda_id"
    t.string "deporte_id", default: "[]"
    t.boolean "vende_ganadores", default: false
    t.index ["grupo_id"], name: "index_cobradores_on_grupo_id"
    t.index ["moneda_id"], name: "index_cobradores_on_moneda_id"
  end

  create_table "config_amounts", force: :cascade do |t|
    t.bigint "rojo_negro_main_id", null: false
    t.integer "amount_race"
    t.float "amount_award"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rojo_negro_main_id"], name: "index_config_amounts_on_rojo_negro_main_id"
  end

  create_table "cuadre_general_caballos", force: :cascade do |t|
    t.bigint "estructura_id"
    t.decimal "venta"
    t.decimal "premio"
    t.decimal "comision"
    t.decimal "utilidad"
    t.integer "moneda"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "carrera_id"
    t.integer "hipodromo_id"
    t.float "monto_otro_grupo"
    t.float "gano_oc", default: 0.0
    t.float "perdio_oc", default: 0.0
    t.float "comision_oc", default: 0.0
    t.index ["estructura_id"], name: "index_cuadre_general_caballos_on_estructura_id"
  end

  create_table "cuadre_general_caballos_logros", force: :cascade do |t|
    t.bigint "estructura_id"
    t.float "venta"
    t.float "premio"
    t.float "comision"
    t.float "utilidad"
    t.integer "moneda"
    t.bigint "carrera_id"
    t.bigint "hipodromo_id"
    t.float "monto_otro_grupo"
    t.float "gano_oc"
    t.float "perdio_oc"
    t.float "comision_oc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_cuadre_general_caballos_logros_on_carrera_id"
    t.index ["estructura_id"], name: "index_cuadre_general_caballos_logros_on_estructura_id"
    t.index ["hipodromo_id"], name: "index_cuadre_general_caballos_logros_on_hipodromo_id"
  end

  create_table "cuadre_general_caballos_puestos", force: :cascade do |t|
    t.bigint "estructura_id"
    t.float "venta"
    t.float "premio"
    t.float "comision"
    t.float "utilidad"
    t.integer "moneda"
    t.bigint "carrera_id"
    t.bigint "hipodromo_id"
    t.float "monto_otro_grupo"
    t.float "gano_oc"
    t.float "perdio_oc"
    t.float "comision_oc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_cuadre_general_caballos_puestos_on_carrera_id"
    t.index ["estructura_id"], name: "index_cuadre_general_caballos_puestos_on_estructura_id"
    t.index ["hipodromo_id"], name: "index_cuadre_general_caballos_puestos_on_hipodromo_id"
  end

  create_table "cuadre_general_deportes", force: :cascade do |t|
    t.bigint "estructura_id"
    t.float "venta"
    t.float "premio"
    t.float "comision"
    t.float "utilidad"
    t.integer "moneda"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "juego_id"
    t.integer "match_id"
    t.float "monto_otro_grupo"
    t.float "gano_oc"
    t.float "perdio_oc"
    t.float "comision_oc"
    t.index ["estructura_id"], name: "index_cuadre_general_deportes_on_estructura_id"
  end

  create_table "cuadre_general_rojo_negros", force: :cascade do |t|
    t.bigint "estructura_id"
    t.float "venta"
    t.float "premio"
    t.float "comision"
    t.float "utilidad"
    t.integer "moneda"
    t.bigint "rojo_negro_main_id"
    t.bigint "hipodromo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estructura_id"], name: "index_cuadre_general_rojo_negros_on_estructura_id"
    t.index ["hipodromo_id"], name: "index_cuadre_general_rojo_negros_on_hipodromo_id"
    t.index ["rojo_negro_main_id"], name: "index_cuadre_general_rojo_negros_on_rojo_negro_main_id"
  end

  create_table "cuadre_general_tablas", force: :cascade do |t|
    t.bigint "estructura_id"
    t.float "venta"
    t.float "premio"
    t.float "comision"
    t.float "utilidad"
    t.integer "moneda"
    t.bigint "carrera_id"
    t.bigint "hipodromo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrera_id"], name: "index_cuadre_general_tablas_on_carrera_id"
    t.index ["estructura_id"], name: "index_cuadre_general_tablas_on_estructura_id"
    t.index ["hipodromo_id"], name: "index_cuadre_general_tablas_on_hipodromo_id"
  end

  create_table "cuentas_bancas", force: :cascade do |t|
    t.string "banco_id"
    t.string "numero_cuenta"
    t.integer "tipo_cuenta"
    t.string "nombre_cuenta"
    t.string "cedula_cuenta"
    t.string "email_cuenta"
    t.integer "moneda"
    t.string "detalle"
    t.string "tipo"
    t.string "grupo_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "cobrador_id", default: 0
    t.boolean "activa", default: true
  end

  create_table "cuentas_clientes", force: :cascade do |t|
    t.string "banco_id"
    t.string "numero_cuenta"
    t.integer "tipo_cuenta"
    t.string "nombre_cuenta"
    t.string "cedula_cuenta"
    t.string "email_cuenta"
    t.integer "moneda"
    t.string "detalle"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "usuarios_taquilla_id"
    t.index ["usuarios_taquilla_id"], name: "index_cuentas_clientes_on_usuarios_taquilla_id"
  end

  create_table "datos_cajero_integradors", force: :cascade do |t|
    t.bigint "integrador_id"
    t.text "datos_cajero"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["integrador_id"], name: "index_datos_cajero_integradors_on_integrador_id"
  end

  create_table "datos_carrera_nyras", force: :cascade do |t|
    t.string "codigo"
    t.integer "numero_carrera"
    t.integer "carrera_id_nyra"
    t.jsonb "retirados"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "datos_usuarios", id: :serial, force: :cascade do |t|
    t.integer "usuario_id"
    t.string "nombre"
    t.string "apellido"
    t.string "telefono"
    t.string "direccion"
    t.string "correo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["usuario_id"], name: "index_datos_usuarios_on_usuario_id"
  end

  create_table "devolucion_sin_saldo_deportes", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.integer "juego_id"
    t.integer "match_id"
    t.float "monto"
    t.string "nombre_match"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["usuarios_taquilla_id"], name: "index_devolucion_sin_saldo_deportes_on_usuarios_taquilla_id"
  end

  create_table "devolucion_sin_saldos", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.bigint "carrera_id"
    t.decimal "monto"
    t.integer "moneda"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_devolucion_sin_saldos_on_carrera_id"
    t.index ["usuarios_taquilla_id"], name: "index_devolucion_sin_saldos_on_usuarios_taquilla_id"
  end

  create_table "enjuegos", force: :cascade do |t|
    t.bigint "propuesta_id"
    t.bigint "usuarios_taquilla_id"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "monto"
    t.integer "status2", default: 0
    t.string "texto_status", default: ""
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.decimal "porcentaje_gt"
    t.decimal "monto_ganar"
    t.integer "moneda"
    t.float "monto_ganar_completo"
    t.integer "ticket_id", default: 0
    t.integer "tickets_detalle_id", default: 0
    t.index ["propuesta_id"], name: "index_enjuegos_on_propuesta_id"
    t.index ["usuarios_taquilla_id"], name: "index_enjuegos_on_usuarios_taquilla_id"
  end

  create_table "envios_faltantes", force: :cascade do |t|
    t.string "integrador"
    t.string "tipo"
    t.string "destino"
    t.string "data_enviada"
    t.string "data_recibida"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "envios_masivos", force: :cascade do |t|
    t.bigint "carrera_id", null: false
    t.bigint "integrador_id", null: false
    t.integer "type_data"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carrera_id"], name: "index_envios_masivos_on_carrera_id"
    t.index ["integrador_id"], name: "index_envios_masivos_on_integrador_id"
  end

  create_table "envios_taquillas", force: :cascade do |t|
    t.string "tipo"
    t.bigint "usuarios_taquilla_id"
    t.bigint "tickets_detalle_id"
    t.text "enviado"
    t.text "recibido"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tickets_detalle_id"], name: "index_envios_taquillas_on_tickets_detalle_id"
    t.index ["usuarios_taquilla_id"], name: "index_envios_taquillas_on_usuarios_taquilla_id"
  end

  create_table "equipos", force: :cascade do |t|
    t.integer "equipo_id"
    t.string "nombre"
    t.string "nombre_largo"
    t.integer "liga_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "picher"
  end

  create_table "errores_cajero_externos", force: :cascade do |t|
    t.integer "user_id"
    t.integer "transaction_id"
    t.float "amount"
    t.string "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "error"
  end

  create_table "errores_cierres", force: :cascade do |t|
    t.text "mensaje"
    t.text "mensaje2"
    t.text "parametros"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "errores_envios_apis", force: :cascade do |t|
    t.integer "integrador_id"
    t.integer "tipo"
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.text "mensaje"
    t.text "mensaje2"
    t.boolean "leido", default: false
    t.integer "status", default: 1
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "liga_id"
    t.integer "match_id"
  end

  create_table "errores_sistemas", force: :cascade do |t|
    t.integer "app"
    t.string "app_detalle"
    t.string "error"
    t.text "detalle"
    t.integer "nivel"
    t.boolean "reportado"
    t.integer "usuario_reporta"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "errores_taquilla_venta", force: :cascade do |t|
    t.integer "producto"
    t.text "error"
    t.jsonb "data"
    t.integer "usuarios_taquilla_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "estructuras", force: :cascade do |t|
    t.string "nombre"
    t.string "representante"
    t.string "rif"
    t.string "telefono"
    t.string "direccion"
    t.string "correo"
    t.integer "tipo"
    t.integer "tipo_id"
    t.integer "padre_id"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.jsonb "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "factor_cambios", force: :cascade do |t|
    t.integer "moneda_id"
    t.integer "grupo_id"
    t.float "valor_dolar", default: 1.0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "cobrador_id", default: 0
  end

  create_table "grupos", force: :cascade do |t|
    t.string "nombre"
    t.string "representante"
    t.string "telefono"
    t.string "correo"
    t.decimal "porcentaje_banca"
    t.decimal "porcentaje_taquilla"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "intermediario_id", default: 0
    t.decimal "porcentaje_intermediario", default: "0.0"
    t.boolean "propone", default: true
    t.boolean "toma", default: true
  end

  create_table "hipodromos", id: :serial, force: :cascade do |t|
    t.string "nombre"
    t.integer "tipo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "nombre_largo"
    t.integer "cantidad_puestos"
    t.string "abreviatura"
    t.boolean "activo", default: true
    t.string "pais"
    t.string "bandera"
    t.boolean "cierre_api", default: true
    t.string "cierre_api_hora", default: ""
    t.string "codigo_nyra", default: ""
    t.string "id_goal"
    t.string "id_video", default: ""
  end

  create_table "historial_tablas", force: :cascade do |t|
    t.bigint "tablas_dinamica_id", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tablas_dinamica_id"], name: "index_historial_tablas_on_tablas_dinamica_id"
  end

  create_table "historial_tasa_grupos", force: :cascade do |t|
    t.bigint "grupo_id"
    t.bigint "moneda_id"
    t.bigint "user_id"
    t.float "tasa_anterior"
    t.float "nueva_tasa"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["grupo_id"], name: "index_historial_tasa_grupos_on_grupo_id"
    t.index ["moneda_id"], name: "index_historial_tasa_grupos_on_moneda_id"
    t.index ["user_id"], name: "index_historial_tasa_grupos_on_user_id"
  end

  create_table "historial_tasas", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "moneda_id"
    t.float "tasa_anterior"
    t.float "tasa_nueva"
    t.string "ip_remota"
    t.integer "grupo_id"
    t.text "geo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "cobrador_id"
    t.index ["user_id"], name: "index_historial_tasas_on_user_id"
  end

  create_table "integradors", force: :cascade do |t|
    t.string "nombre"
    t.string "representante"
    t.string "telefono"
    t.string "api_key"
    t.integer "grupo_id"
    t.string "ip_integrador"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "usa_cajero_externo", default: false
    t.float "min_und", default: 0.0
    t.float "max_und", default: 0.0
  end

  create_table "intermediarios", force: :cascade do |t|
    t.string "nombre"
    t.string "representante"
    t.string "direccion"
    t.string "rif"
    t.string "telefono"
    t.string "correo"
    t.boolean "activo"
    t.decimal "porcentaje_banca"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "international_videos", force: :cascade do |t|
    t.datetime "date", precision: nil
    t.jsonb "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "jornada_deportes", force: :cascade do |t|
    t.integer "juego_id"
    t.integer "liga_id"
    t.datetime "fecha", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "jornadas", id: :serial, force: :cascade do |t|
    t.integer "hipodromo_id"
    t.datetime "fecha", precision: nil
    t.integer "cantidad_carreras"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["hipodromo_id"], name: "index_jornadas_on_hipodromo_id"
  end

  create_table "juegos", force: :cascade do |t|
    t.integer "juego_id"
    t.string "nombre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "imagen"
  end

  create_table "juegos_premiados", force: :cascade do |t|
    t.bigint "match_id"
    t.bigint "usuarios_taquilla_id"
    t.bigint "propuestas_deporte_id"
    t.bigint "operaciones_cajero_id"
    t.boolean "activo"
    t.boolean "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["match_id"], name: "index_juegos_premiados_on_match_id"
    t.index ["operaciones_cajero_id"], name: "index_juegos_premiados_on_operaciones_cajero_id"
    t.index ["propuestas_deporte_id"], name: "index_juegos_premiados_on_propuestas_deporte_id"
    t.index ["usuarios_taquilla_id"], name: "index_juegos_premiados_on_usuarios_taquilla_id"
  end

  create_table "ligas", force: :cascade do |t|
    t.integer "juego_id"
    t.integer "liga_id"
    t.string "nombre"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "activo"
    t.integer "status"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "match_id"
    t.string "nombre"
    t.string "utc"
    t.datetime "local", precision: nil
    t.text "match"
    t.integer "juego_id"
    t.integer "liga_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "activo"
    t.integer "status"
    t.integer "jornada_id"
    t.boolean "usa_empate", default: false
    t.text "data"
    t.integer "id_base"
    t.boolean "show_next", default: false
  end

  create_table "menu_usuarios", force: :cascade do |t|
    t.bigint "user_id"
    t.text "menu"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_menu_usuarios_on_user_id"
  end

  create_table "modelos_tablas", force: :cascade do |t|
    t.string "descrip"
    t.float "suma"
    t.float "cuanto_paga"
    t.float "minimo"
    t.float "maximo"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "factor", default: 1
  end

  create_table "monedas", force: :cascade do |t|
    t.string "pais"
    t.string "nombre"
    t.string "abreviatura"
    t.boolean "activa", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "monedas_grupos", force: :cascade do |t|
    t.bigint "grupo_id"
    t.integer "moneda_id"
    t.float "tasa_unidad"
    t.boolean "activa", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["grupo_id"], name: "index_monedas_grupos_on_grupo_id"
  end

  create_table "montos_generador_propuesta", force: :cascade do |t|
    t.jsonb "data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "movimiento_cajeros", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id", null: false
    t.bigint "user_id", null: false
    t.float "monto"
    t.integer "type_operation"
    t.string "detalle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_movimiento_cajeros_on_user_id"
    t.index ["usuarios_taquilla_id"], name: "index_movimiento_cajeros_on_usuarios_taquilla_id"
  end

  create_table "operaciones_cajero_apis", force: :cascade do |t|
    t.bigint "integrador_id"
    t.integer "transaction_id"
    t.string "details"
    t.float "amount"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["integrador_id"], name: "index_operaciones_cajero_apis_on_integrador_id"
  end

  create_table "operaciones_cajero_integradors", force: :cascade do |t|
    t.integer "operacaiones_cajero_id"
    t.integer "usuarios_taquilla_id"
    t.integer "integrador_id"
    t.decimal "monto"
    t.string "detalle"
    t.integer "tipo"
    t.boolean "enviado", default: false
    t.boolean "procesado", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "operaciones_cajeros", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.string "descripcion"
    t.decimal "saldo_anterior"
    t.decimal "monto"
    t.decimal "saldo_actual"
    t.integer "propuesta_id", default: 0
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "moneda"
    t.integer "tipo", default: 0
    t.decimal "porcentaje_gt"
    t.decimal "porcentaje_bg"
    t.integer "tipo_app", default: 1
    t.float "monto_dolar", default: 0.0
    t.index ["usuarios_taquilla_id"], name: "index_operaciones_cajeros_on_usuarios_taquilla_id"
  end

  create_table "pagos_socios", force: :cascade do |t|
    t.bigint "socio_id"
    t.bigint "app_id"
    t.string "referencia"
    t.float "monto_participacion"
    t.float "monto_pagado"
    t.float "saldo"
    t.integer "moneda"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["app_id"], name: "index_pagos_socios_on_app_id"
    t.index ["socio_id"], name: "index_pagos_socios_on_socio_id"
  end

  create_table "patron_tablas", force: :cascade do |t|
    t.bigint "modelos_tabla_id", null: false
    t.float "desde"
    t.float "hasta"
    t.integer "patron"
    t.integer "cantidad_tablas"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["modelos_tabla_id"], name: "index_patron_tablas_on_modelos_tabla_id"
  end

  create_table "porcentajes_socios", force: :cascade do |t|
    t.bigint "socio_id"
    t.bigint "app_id"
    t.float "porcentaje"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["app_id"], name: "index_porcentajes_socios_on_app_id"
    t.index ["socio_id"], name: "index_porcentajes_socios_on_socio_id"
  end

  create_table "postimes", force: :cascade do |t|
    t.bigint "user_id"
    t.string "hora_anterior"
    t.string "nueva_hora"
    t.integer "carrera_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_postimes_on_user_id"
  end

  create_table "premiacion_caballos_puestos", force: :cascade do |t|
    t.integer "moneda"
    t.bigint "carrera_id"
    t.integer "id_quien_juega"
    t.integer "id_quien_banquea"
    t.integer "id_gana"
    t.float "monto_pagado_completo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_premiacion_caballos_puestos_on_carrera_id"
  end

  create_table "premiacion_deportes", force: :cascade do |t|
    t.integer "juego_id"
    t.integer "liga_id"
    t.integer "match_id"
    t.integer "tipo_apuesta"
    t.integer "id_quien_juega"
    t.integer "id_quien_banquea"
    t.decimal "monto_quien_juega"
    t.decimal "monto_quien_banquea"
    t.integer "usuario_premia_id"
    t.integer "id_equipo_gana"
    t.boolean "repremiado"
    t.decimal "monto_pagado"
    t.decimal "monto_pagado_completo"
    t.integer "moneda"
    t.integer "id_gana"
    t.decimal "porcentaje_gt"
    t.decimal "porcentaje_bg"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "premiacions", force: :cascade do |t|
    t.bigint "carrera_id"
    t.bigint "caballos_carrera_id"
    t.integer "tipo_apuesta"
    t.integer "id_quien_juega"
    t.integer "id_quien_banquea"
    t.decimal "monto_quien_juega"
    t.decimal "monto_quien_banquea"
    t.integer "usuario_premia_id"
    t.integer "llegada_caballo"
    t.boolean "repremiado"
    t.decimal "monto_pagado"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "monto_pagado_completo"
    t.integer "moneda"
    t.integer "id_gana", default: 0
    t.decimal "porcentaje_gt"
    t.decimal "porcentaje_bg"
    t.index ["caballos_carrera_id"], name: "index_premiacions_on_caballos_carrera_id"
    t.index ["carrera_id"], name: "index_premiacions_on_carrera_id"
  end

  create_table "premioas_ingresados_apis", force: :cascade do |t|
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.text "resultado"
    t.integer "status", default: 1
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "premios_ingresados", force: :cascade do |t|
    t.integer "usuario_premia"
    t.integer "hipodromo_id"
    t.integer "jornada_id"
    t.integer "carrera_id"
    t.text "caballos"
    t.boolean "repremio"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "premios_ingresados_deportes", force: :cascade do |t|
    t.integer "usuario_premia"
    t.integer "juego_id"
    t.integer "liga_id"
    t.integer "match_id"
    t.text "resultado"
    t.boolean "repremio"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "propuesta", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.integer "caballo_id"
    t.integer "accion_id"
    t.integer "tipo_id"
    t.float "monto"
    t.integer "moneda"
    t.boolean "activa", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status"
    t.integer "status2", default: 0
    t.integer "corte_id", default: 0
    t.string "texto_status"
    t.decimal "porcentaje_gt", default: "0.0"
    t.decimal "monto_ganar", default: "0.0"
    t.float "monto_gana_completo"
    t.float "monto_enjuego"
    t.integer "ticket_id", default: 0
    t.integer "tickets_detalle_id", default: 0
    t.index ["usuarios_taquilla_id"], name: "index_propuesta_on_usuarios_taquilla_id"
  end

  create_table "propuestas_caballos", force: :cascade do |t|
    t.integer "deporte_id", default: 998
    t.integer "hipodromo_id", default: 0
    t.integer "carrera_id", default: 0
    t.integer "caballos_carrera_id", default: 0
    t.integer "tipo_apuesta_id", default: 0
    t.string "puesto", default: ""
    t.integer "accion_id", default: 0
    t.integer "tipo_apuesta", default: 1
    t.float "logro", default: 0.0
    t.float "monto", default: 0.0
    t.integer "id_juega", default: 0
    t.integer "id_banquea", default: 0
    t.integer "id_propone", default: 0
    t.integer "id_gana", default: 0
    t.float "cuanto_gana", default: 0.0
    t.float "cuanto_gana_completo"
    t.float "cuanto_pierde"
    t.integer "status", default: 1
    t.integer "status2", default: 1
    t.boolean "activa", default: true
    t.integer "id_padre", default: 0
    t.integer "moneda", default: 1
    t.integer "grupo_id", default: 0
    t.boolean "cruzo_igual_accion"
    t.string "texto_cruzado", default: ""
    t.integer "operaciones_cajero_id", default: 0
    t.integer "corte_id", default: 0
    t.integer "tipo_juego", default: 1
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "texto_jugada", default: ""
    t.integer "ticket_id_juega", default: 0
    t.integer "tickets_detalle_id_juega", default: 0
    t.integer "ticket_id_banquea", default: 0
    t.integer "tickets_detalle_id_banquea", default: 0
    t.integer "reference_id_juega", default: 0
    t.integer "reference_id_banquea", default: 0
    t.boolean "premiada", default: false
    t.index ["created_at", "status", "status2", "id_propone", "id_juega", "id_banquea", "caballos_carrera_id"], name: "index_on_frequent_query_sport"
  end

  create_table "propuestas_caballos_puestos", force: :cascade do |t|
    t.bigint "grupo_id"
    t.bigint "hipodromo_id"
    t.bigint "carrera_id"
    t.bigint "caballos_carrera_id"
    t.string "puesto", default: ""
    t.integer "accion_id"
    t.bigint "tipo_apuesta_id"
    t.string "tipo_puesto_nombre", default: ""
    t.string "texto_jugada", default: ""
    t.integer "moneda", default: 2
    t.decimal "monto"
    t.integer "id_propone", default: 0
    t.integer "id_juega", default: 0
    t.integer "id_banquea", default: 0
    t.integer "id_gana", default: 0
    t.decimal "cuanto_gana", default: "0.0"
    t.decimal "cuanto_gana_completo", default: "0.0"
    t.decimal "cuanto_pierde", default: "0.0"
    t.integer "status", default: 0
    t.integer "status2", default: 0
    t.boolean "activa", default: true
    t.integer "id_padre", default: 0
    t.integer "corte_id", default: 0
    t.integer "tipo_juego", default: 3
    t.bigint "operaciones_cajero_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "ticket_id_juega", default: 0
    t.integer "tickets_detalle_id_juega", default: 0
    t.integer "ticket_id_banquea", default: 0
    t.integer "tickets_detalle_id_banquea", default: 0
    t.integer "reference_id_juega", default: 0
    t.integer "reference_id_banquea", default: 0
    t.boolean "premiada", default: false
    t.integer "id_pierde"
    t.datetime "match_at"
    t.float "monto_original_juega", default: 0.0
    t.float "monto_original_banquea", default: 0.0
    t.index ["caballos_carrera_id"], name: "index_propuestas_caballos_puestos_on_caballos_carrera_id"
    t.index ["carrera_id"], name: "index_propuestas_caballos_puestos_on_carrera_id"
    t.index ["created_at", "status", "status2", "id_propone", "id_juega", "id_banquea", "caballos_carrera_id"], name: "index_on_frequent_query"
    t.index ["grupo_id"], name: "index_propuestas_caballos_puestos_on_grupo_id"
    t.index ["hipodromo_id"], name: "index_propuestas_caballos_puestos_on_hipodromo_id"
    t.index ["operaciones_cajero_id"], name: "index_propuestas_caballos_puestos_on_operaciones_cajero_id"
    t.index ["tipo_apuesta_id"], name: "index_propuestas_caballos_puestos_on_tipo_apuesta_id"
  end

  create_table "propuestas_deportes", force: :cascade do |t|
    t.integer "deporte_id", default: 0
    t.integer "liga_id", default: 0
    t.integer "match_id", default: 0
    t.integer "equipo_id", default: 0
    t.integer "accion_id", default: 0
    t.integer "tipo_apuesta", default: 0
    t.float "logro", default: 0.0
    t.float "monto", default: 0.0
    t.float "carreras_dadas", default: 0.0
    t.float "alta_baja", default: 0.0
    t.integer "tipo_altabaja", default: 0
    t.integer "id_juega", default: 0
    t.integer "id_banquea", default: 0
    t.float "cuanto_gana", default: 0.0
    t.float "cuanto_gana_completo"
    t.integer "status", default: 1
    t.integer "status2", default: 1
    t.boolean "activa", default: true
    t.integer "id_padre", default: 0
    t.integer "moneda", default: 1
    t.integer "grupo_id", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "cuanto_pierde"
    t.boolean "cruzo_igual_accion", default: false
    t.string "texto_cruzado"
    t.integer "id_propone"
    t.integer "id_gana"
    t.integer "operaciones_cajero_id"
    t.integer "corte_id", default: 0
    t.integer "equipo_contra", default: 0
    t.string "texto_jugada", default: ""
    t.integer "ticket_id_juega", default: 0
    t.integer "tickets_detalle_id_juega", default: 0
    t.integer "ticket_id_banquea", default: 0
    t.integer "tickets_detalle_id_banquea", default: 0
    t.integer "reference_id_juega", default: 0
    t.integer "reference_id_banquea", default: 0
    t.boolean "premiada", default: false
    t.string "texto_igual_condicion", default: ""
  end

  create_table "prospectos", force: :cascade do |t|
    t.text "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "reglas", force: :cascade do |t|
    t.text "texto"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "resultados_nyras", force: :cascade do |t|
    t.bigint "carrera_id"
    t.jsonb "resultados"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_resultados_nyras_on_carrera_id"
  end

  create_table "retornos_bloque_apis", force: :cascade do |t|
    t.integer "tipo"
    t.integer "hipodromo_id"
    t.integer "carrera_id"
    t.text "data_enviada"
    t.text "data_recibida"
    t.boolean "procesada"
    t.boolean "reintento"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "integrador_id", default: 0
    t.integer "liga_id"
    t.integer "match_id"
  end

  create_table "rojo_negro_mains", force: :cascade do |t|
    t.bigint "jornada_id", null: false
    t.jsonb "carreras"
    t.integer "status"
    t.string "hipodromo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_races", default: 8
    t.integer "races_awared", default: 0
    t.boolean "started", default: false
    t.index ["jornada_id"], name: "index_rojo_negro_mains_on_jornada_id"
  end

  create_table "rojo_negros", force: :cascade do |t|
    t.bigint "carrera_id", null: false
    t.jsonb "rojos"
    t.jsonb "negros"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "numero_carrera"
    t.index ["carrera_id"], name: "index_rojo_negros_on_carrera_id"
  end

  create_table "ruta_videos", force: :cascade do |t|
    t.string "nombre"
    t.integer "tipo"
    t.string "hipodromo"
    t.text "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "saldos_iniciodia", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.decimal "monto_bs"
    t.decimal "monto_usd"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["usuarios_taquilla_id"], name: "index_saldos_iniciodia_on_usuarios_taquilla_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "socios", force: :cascade do |t|
    t.string "nombre"
    t.string "apellido"
    t.integer "nivel"
    t.boolean "activo"
    t.datetime "ultimo_pago", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "solicitud_recargas", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.integer "tipo"
    t.bigint "cuentas_banca_id"
    t.datetime "fecha_deposito", precision: nil
    t.decimal "monto"
    t.string "numero_operacion"
    t.text "foto"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "imagen"
    t.float "tasa"
    t.float "monto_usd"
    t.integer "user_id"
    t.index ["cuentas_banca_id"], name: "index_solicitud_recargas_on_cuentas_banca_id"
    t.index ["usuarios_taquilla_id"], name: "index_solicitud_recargas_on_usuarios_taquilla_id"
  end

  create_table "solicitud_retiros", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.integer "tipo"
    t.bigint "cuentas_cliente_id"
    t.decimal "monto"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "detalle"
    t.float "tasa"
    t.float "monto_moneda"
    t.integer "user_id"
    t.index ["cuentas_cliente_id"], name: "index_solicitud_retiros_on_cuentas_cliente_id"
    t.index ["usuarios_taquilla_id"], name: "index_solicitud_retiros_on_usuarios_taquilla_id"
  end

  create_table "tablas_detalles", force: :cascade do |t|
    t.bigint "tablas_dinamica_id", null: false
    t.bigint "caballos_carrera_id", null: false
    t.boolean "retirado", default: false
    t.float "valor"
    t.integer "cantidad_tablas"
    t.integer "cantidad_vendida", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cantidad_inicial"
    t.integer "cantidad_vendida_total", default: 0
    t.index ["caballos_carrera_id"], name: "index_tablas_detalles_on_caballos_carrera_id"
    t.index ["tablas_dinamica_id"], name: "index_tablas_detalles_on_tablas_dinamica_id"
  end

  create_table "tablas_dinamicas", force: :cascade do |t|
    t.bigint "hipodromo_id", null: false
    t.bigint "jornada_id", null: false
    t.bigint "carrera_id", null: false
    t.float "monto_pagar"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "modelo_id", default: 0
    t.index ["carrera_id"], name: "index_tablas_dinamicas_on_carrera_id"
    t.index ["hipodromo_id"], name: "index_tablas_dinamicas_on_hipodromo_id"
    t.index ["jornada_id"], name: "index_tablas_dinamicas_on_jornada_id"
  end

  create_table "tablas_fijas", force: :cascade do |t|
    t.bigint "hipodromo_id"
    t.bigint "carrera_id"
    t.float "premio"
    t.integer "disponible"
    t.float "comision"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["carrera_id"], name: "index_tablas_fijas_on_carrera_id"
    t.index ["hipodromo_id"], name: "index_tablas_fijas_on_hipodromo_id"
  end

  create_table "tablas_fijas_detalles", force: :cascade do |t|
    t.bigint "tablas_fija_id"
    t.integer "caballo_id"
    t.float "costo"
    t.integer "status"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tablas_fija_id"], name: "index_tablas_fijas_detalles_on_tablas_fija_id"
  end

  create_table "ticket_rojo_negros", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id", null: false
    t.bigint "rojo_negro_main_id", null: false
    t.float "monto"
    t.jsonb "detalle"
    t.float "monto_original"
    t.integer "status"
    t.float "monto_ganado", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "carreras_jugadas"
    t.integer "cantidad_vidas"
    t.string "gticket"
    t.index ["rojo_negro_main_id"], name: "index_ticket_rojo_negros_on_rojo_negro_main_id"
    t.index ["usuarios_taquilla_id"], name: "index_ticket_rojo_negros_on_usuarios_taquilla_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id"
    t.integer "tipo_juego", default: 1
    t.integer "status1", default: 0
    t.integer "status2", default: 0
    t.integer "status3", default: 0
    t.float "monto", default: 0.0
    t.float "monto_gano", default: 0.0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["usuarios_taquilla_id"], name: "index_tickets_on_usuarios_taquilla_id"
  end

  create_table "tickets_detalles", force: :cascade do |t|
    t.bigint "ticket_id"
    t.integer "propuesta_id", default: 0
    t.integer "enjuego_id", default: 0
    t.integer "status1", default: 0
    t.integer "status2", default: 0
    t.integer "status3", default: 0
    t.string "detalle", default: ""
    t.float "monto", default: 0.0
    t.float "monto_gano", default: 0.0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "propuesta_deporte_id", default: 0
    t.integer "propuesta_caballo_id", default: 0
    t.integer "id_propone", default: 0
    t.integer "id_toma", default: 0
    t.integer "propuesta_caballos_puesto_id"
    t.string "gticket", default: ""
    t.float "monto_original"
    t.index ["ticket_id"], name: "index_tickets_detalles_on_ticket_id"
  end

  create_table "tickets_tablas", force: :cascade do |t|
    t.bigint "usuarios_taquilla_id", null: false
    t.bigint "tablas_detalle_id", null: false
    t.bigint "caballos_carrera_id", null: false
    t.bigint "carrera_id", null: false
    t.integer "cantidad_tablas"
    t.float "valor"
    t.float "total"
    t.float "monto_ganado", default: 0.0
    t.string "detalle"
    t.string "gticket"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["caballos_carrera_id"], name: "index_tickets_tablas_on_caballos_carrera_id"
    t.index ["carrera_id"], name: "index_tickets_tablas_on_carrera_id"
    t.index ["tablas_detalle_id"], name: "index_tickets_tablas_on_tablas_detalle_id"
    t.index ["usuarios_taquilla_id"], name: "index_tickets_tablas_on_usuarios_taquilla_id"
  end

  create_table "tipo_apuesta", force: :cascade do |t|
    t.string "nombre"
    t.string "forma_pagar"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "transacciones_bancos", force: :cascade do |t|
    t.string "banco_id"
    t.integer "tipo_operacion"
    t.integer "forma_pago"
    t.decimal "monto"
    t.integer "status"
    t.string "referencia"
    t.integer "cuenta_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "tipo"
    t.integer "grupo_id"
    t.boolean "activo"
    t.integer "intermediario_id"
    t.integer "cobrador_id"
  end

  create_table "usuarios", id: :serial, force: :cascade do |t|
    t.string "nombre"
    t.string "clave"
    t.integer "estructura_id"
    t.string "token"
    t.boolean "activo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "usuarios_generadors", force: :cascade do |t|
    t.string "correo"
    t.string "clave"
    t.float "porcentaje"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "can_send", default: true
  end

  create_table "usuarios_taquillas", force: :cascade do |t|
    t.string "nombre"
    t.string "clave"
    t.string "alias"
    t.string "telefono"
    t.string "correo"
    t.float "saldo_bs"
    t.float "saldo_usd"
    t.boolean "activo"
    t.integer "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "grupo_id"
    t.string "token"
    t.decimal "comision"
    t.string "cedula"
    t.decimal "jugada_minima_bs", default: "0.0"
    t.decimal "jugada_maxima_bs", default: "0.0"
    t.decimal "jugada_minima_usd", default: "0.0"
    t.decimal "jugada_maxima_usd", default: "0.0"
    t.boolean "prepagado", default: false
    t.integer "moneda_default", default: 1
    t.integer "vista_default", default: 1
    t.integer "cobrador_id", default: 0
    t.string "token_externo"
    t.boolean "externo", default: false
    t.integer "integrador_id"
    t.string "cliente_id"
    t.boolean "propone", default: true
    t.boolean "toma", default: true
    t.text "url_ganadores"
    t.string "idioma", default: "es"
    t.string "tipo_logro", default: "us"
    t.string "simbolo_moneda_default", default: "Bs."
    t.float "moneda_default_dolar", default: 0.0
    t.boolean "usa_cajero_externo", default: false
    t.boolean "need_confirm", default: true
    t.boolean "demo", default: false
    t.integer "tipo", default: 1
    t.string "id_agente", default: ""
    t.index ["cliente_id"], name: "index_usuarios_taquillas_on_cliente_id"
    t.index ["correo"], name: "index_usuarios_taquillas_on_correo"
    t.index ["grupo_id"], name: "index_usuarios_taquillas_on_grupo_id"
    t.index ["integrador_id"], name: "index_usuarios_taquillas_on_integrador_id"
  end

  add_foreign_key "bancos_clientes", "usuarios_taquillas"
  add_foreign_key "caballos_carreras", "carreras"
  add_foreign_key "caballos_retirados_confirmacions", "caballos_carreras"
  add_foreign_key "caballos_retirados_confirmacions", "carreras"
  add_foreign_key "caballos_retirados_confirmacions", "hipodromos"
  add_foreign_key "caballos_retirados_confirmacions", "users"
  add_foreign_key "carreras", "jornadas"
  add_foreign_key "carreras_p_logros", "carreras"
  add_foreign_key "carreras_p_logros", "operaciones_cajeros"
  add_foreign_key "carreras_p_logros", "premios_ingresados"
  add_foreign_key "carreras_p_logros", "propuestas_caballos"
  add_foreign_key "carreras_p_logros", "usuarios_taquillas"
  add_foreign_key "carreras_p_puestos", "carreras"
  add_foreign_key "carreras_p_puestos", "operaciones_cajeros"
  add_foreign_key "carreras_p_puestos", "premios_ingresados"
  add_foreign_key "carreras_p_puestos", "propuestas_caballos_puestos"
  add_foreign_key "carreras_p_puestos", "usuarios_taquillas"
  add_foreign_key "carreras_premiadas", "carreras"
  add_foreign_key "carreras_premiadas", "enjuegos"
  add_foreign_key "carreras_premiadas", "operaciones_cajeros"
  add_foreign_key "carreras_premiadas", "premios_ingresados"
  add_foreign_key "carreras_premiadas", "usuarios_taquillas"
  add_foreign_key "chats", "users"
  add_foreign_key "cobradores", "grupos"
  add_foreign_key "cobradores", "monedas"
  add_foreign_key "config_amounts", "rojo_negro_mains"
  add_foreign_key "cuadre_general_caballos", "estructuras"
  add_foreign_key "cuadre_general_caballos_logros", "carreras"
  add_foreign_key "cuadre_general_caballos_logros", "estructuras"
  add_foreign_key "cuadre_general_caballos_logros", "hipodromos"
  add_foreign_key "cuadre_general_caballos_puestos", "carreras"
  add_foreign_key "cuadre_general_caballos_puestos", "estructuras"
  add_foreign_key "cuadre_general_caballos_puestos", "hipodromos"
  add_foreign_key "cuadre_general_deportes", "estructuras"
  add_foreign_key "cuadre_general_rojo_negros", "estructuras"
  add_foreign_key "cuadre_general_rojo_negros", "hipodromos"
  add_foreign_key "cuadre_general_rojo_negros", "rojo_negro_mains"
  add_foreign_key "cuadre_general_tablas", "carreras"
  add_foreign_key "cuadre_general_tablas", "estructuras"
  add_foreign_key "cuadre_general_tablas", "hipodromos"
  add_foreign_key "cuentas_clientes", "usuarios_taquillas"
  add_foreign_key "datos_cajero_integradors", "integradors"
  add_foreign_key "datos_usuarios", "usuarios"
  add_foreign_key "devolucion_sin_saldo_deportes", "usuarios_taquillas"
  add_foreign_key "devolucion_sin_saldos", "carreras"
  add_foreign_key "devolucion_sin_saldos", "usuarios_taquillas"
  add_foreign_key "enjuegos", "propuesta", column: "propuesta_id"
  add_foreign_key "enjuegos", "usuarios_taquillas"
  add_foreign_key "envios_masivos", "carreras"
  add_foreign_key "envios_masivos", "integradors"
  add_foreign_key "envios_taquillas", "tickets_detalles"
  add_foreign_key "envios_taquillas", "usuarios_taquillas"
  add_foreign_key "historial_tablas", "tablas_dinamicas"
  add_foreign_key "historial_tasas", "users"
  add_foreign_key "jornadas", "hipodromos"
  add_foreign_key "juegos_premiados", "matches"
  add_foreign_key "juegos_premiados", "operaciones_cajeros"
  add_foreign_key "juegos_premiados", "propuestas_deportes"
  add_foreign_key "juegos_premiados", "usuarios_taquillas"
  add_foreign_key "menu_usuarios", "users"
  add_foreign_key "monedas_grupos", "grupos"
  add_foreign_key "movimiento_cajeros", "users"
  add_foreign_key "movimiento_cajeros", "usuarios_taquillas"
  add_foreign_key "operaciones_cajero_apis", "integradors"
  add_foreign_key "operaciones_cajeros", "usuarios_taquillas"
  add_foreign_key "pagos_socios", "apps"
  add_foreign_key "pagos_socios", "socios"
  add_foreign_key "patron_tablas", "modelos_tablas"
  add_foreign_key "porcentajes_socios", "socios"
  add_foreign_key "postimes", "users"
  add_foreign_key "premiacion_caballos_puestos", "carreras"
  add_foreign_key "premiacions", "caballos_carreras"
  add_foreign_key "premiacions", "carreras"
  add_foreign_key "propuesta", "usuarios_taquillas"
  add_foreign_key "propuestas_caballos_puestos", "caballos_carreras"
  add_foreign_key "propuestas_caballos_puestos", "carreras"
  add_foreign_key "propuestas_caballos_puestos", "grupos"
  add_foreign_key "propuestas_caballos_puestos", "hipodromos"
  add_foreign_key "propuestas_caballos_puestos", "operaciones_cajeros"
  add_foreign_key "propuestas_caballos_puestos", "tipo_apuesta", column: "tipo_apuesta_id"
  add_foreign_key "rojo_negro_mains", "jornadas"
  add_foreign_key "rojo_negros", "carreras"
  add_foreign_key "saldos_iniciodia", "usuarios_taquillas"
  add_foreign_key "solicitud_recargas", "cuentas_bancas"
  add_foreign_key "solicitud_recargas", "usuarios_taquillas"
  add_foreign_key "solicitud_retiros", "cuentas_clientes"
  add_foreign_key "solicitud_retiros", "usuarios_taquillas"
  add_foreign_key "tablas_detalles", "caballos_carreras"
  add_foreign_key "tablas_detalles", "tablas_dinamicas"
  add_foreign_key "tablas_dinamicas", "carreras"
  add_foreign_key "tablas_dinamicas", "hipodromos"
  add_foreign_key "tablas_dinamicas", "jornadas"
  add_foreign_key "tablas_fijas", "carreras"
  add_foreign_key "tablas_fijas", "hipodromos"
  add_foreign_key "tablas_fijas_detalles", "tablas_fijas"
  add_foreign_key "ticket_rojo_negros", "rojo_negro_mains"
  add_foreign_key "ticket_rojo_negros", "usuarios_taquillas"
  add_foreign_key "tickets", "usuarios_taquillas"
  add_foreign_key "tickets_detalles", "tickets"
  add_foreign_key "tickets_tablas", "caballos_carreras"
  add_foreign_key "tickets_tablas", "carreras"
  add_foreign_key "tickets_tablas", "tablas_detalles"
  add_foreign_key "tickets_tablas", "usuarios_taquillas"
  add_foreign_key "usuarios_taquillas", "grupos"
end
