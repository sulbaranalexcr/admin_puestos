class Unica::EnviosMasivosController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :seguridad_cuentas, only: [:index]
  include ApiHelper
  include ApplicationHelper

  def index
    @hipodromos = Hipodromo.where(activo: true)
  end

  def res_enviar
    carrera_id = params[:id]
    bus_carrera = Carrera.find(carrera_id)
    hipodromo_id = bus_carrera.jornada.hipodromo.id
    tipo = params[:tipo].to_i
    case tipo
    when 1
    when 3
      enviar_retirados(hipodromo_id, carrera_id, 3)    
    when 4
      enviar_devueltas(hipodromo_id, carrera_id, 4)    
    when 5
    when 6 
      enviar_eliminadas(hipodromo_id, carrera_id, 6)
    end
  end

  def enviar
    if params[:tipo].to_i == 4
      hipodromo_id = Carrera.find(params[:id]).jornada.hipodromo_id
      enviar_devueltas(hipodromo_id, params[:id], 4)    
    elsif params[:tipo].to_i == 3
      hipodromo_id = Carrera.find(params[:id]).jornada.hipodromo_id
      enviar_retirados(hipodromo_id, params[:id], 3)    
    else
      data = EnviosMasivo.find_by(carrera_id: params[:id], integrador_id: params[:integrador].to_i, type_data: params[:tipo].to_i)
      if data.present?
        hipodromo_id = data.carrera.jornada.hipodromo_id
        acreditar_saldos_cajero_externo(data.integrador_id, data.data, hipodromo_id, data.carrera_id, data.type_data, 0)
        render json: { 'message' => 'Envio exitoso.' }, status: :ok
      else
        render json: { 'message' => 'No hay datos para el tipo seleccionado.' }, status: :unprocessable_entity
      end
    end
  end

  def enviar_devueltas(hipodromo_id, carrera_id, tipo_id)
    array_cajero = []
    tra_id = 0
    ref_id = 0
    PropuestasCaballosPuesto.where(carrera_id: carrera_id, status: 4, status2: 7).each do |pro|
      bus_user = UsuariosTaquilla.find(pro.id_propone)
      next unless bus_user.usa_cajero_externo 
     
      if pro.id_propone == pro.id_juega
        tra_id = pro.tickets_detalle_id_juega
        ref_id = pro.reference_id_juega
      else
        tra_id = pro.tickets_detalle_id_banquea
        ref_id = pro.reference_id_banquea
      end
      descripcion = "Reverso/No igualada #{pro.texto_jugada}"
      monto_t = pro.monto * bus_user.moneda_default_dolar.to_f
      array_cajero << { 'id' => bus_user.cliente_id, 'taq_id' => bus_user.id, 'transaction_id' => tra_id,
                        'reference_id' => ref_id, 'amount' => monto_t.to_f, 'details' => descripcion }
    end
    render json: { 'message' => 'No hay datos para enviar.' }, status: :unprocessable_entity and return if array_cajero.empty?

    PremiacionApiJob.perform_async array_cajero, hipodromo_id, carrera_id, tipo_id
    render json: { 'message' => 'OK' }
  end

  def search_data
    data = EnviosMasivo.where(carrera_id: params[:id], type_data: params[:tipo].to_i, integrador_id: params[:integrador].to_i).last
    @json_data = if data.present?
                   data.data
                 else
                   { msg: 'No hay datos para el tipo seleccionado.' }
                 end

    render partial: 'data_show'
  end

  def enviar_retirados(hipodromo_id, carrera_id, tipo_id)
    todos_caballos_nombre = true
    arreglo_enjuego = []
    arreglo_propuestas = []
    hipodromo = Carrera.find(carrera_id).jornada.hipodromo
    retirar_tipo = []
    retirados_propuestas = []
    retirados_enjuego = []
    @retirar_array_cajero = []
    @nojuega_array_cajero = []
    @usuarios_interno_ganan = []

    @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
    @ids_cajero_externop =  ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json

    # @todos_ids = ActiveRecord::Base.connection.execute('select id,(select factor_cambios.valor_dolar from factor_cambios where factor_cambios.cobrador_id > 0 and factor_cambios.grupo_id = usuarios_taquillas.grupo_id and factor_cambios.cobrador_id = usuarios_taquillas.cobrador_id and factor_cambios.moneda_id = usuarios_taquillas.moneda_default) as valor_moneda from usuarios_taquillas').as_json
    # @ids_cajero_externop = ActiveRecord::Base.connection.execute('select id,cliente_id, (select factor_cambios.valor_dolar from factor_cambios where factor_cambios.grupo_id = usuarios_taquillas.grupo_id and factor_cambios.cobrador_id = usuarios_taquillas.cobrador_id and factor_cambios.moneda_id = usuarios_taquillas.moneda_default) as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json

    carr = Carrera.find(carrera_id)
    caballos = carr.caballos_carrera.where(retirado: true)
    begin
      ActiveRecord::Base.transaction do
        if caballos.count > 0
          caballos.each do |cab|
            enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: cab.id, status: 4, status2: [7, 13])
            if enjuego.present?
              enjuego.each do |enj|
                mensaje = enj.status2 == 13 ? 'Devolucion/Retirado' : 'No entra en juego'
                if enj.id_banquea > 0 && enj.id_juega > 0
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
                  busca_user = buscar_cliente_cajero(id_quien_juega)
                  if busca_user != '0'
                    set_envios_api(3, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega,
                                    cuanto_juega.to_f, mensaje)
                  end
                  busca_user = buscar_cliente_cajero(id_quien_banquea)
                  if busca_user != '0'
                    set_envios_api(3, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea,
                                    monto_banqueado.to_f, mensaje)
                  end
                else
                  busca_user = buscar_cliente_cajero(enj.id_propone)
                  if busca_user != '0'
                    if enj.id_propone == enj.id_juega
                      tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                      reference_id_propone = enj.reference_id_juega
                    else
                      tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                      reference_id_propone = enj.reference_id_banquea
                    end
                    set_envios_api(3, busca_user, tickets_detalle_id_propone, reference_id_propone,
                                    enj.monto.to_f, mensaje)
                  end
                end
              end
            end
          end
          if @retirar_array_cajero.length.positive?
            PremiacionApiJob.perform_async @retirar_array_cajero, hipodromo.id, carrera_id, 3
          end
        end
      end
    end
    render json: { 'message' => 'OK' }
  end

  def enviar_eliminadas(hipodromo_id, carrera_id, tipo_id)
    array_cajero = []
    tra_id = 0
    ref_id = 0
    PropuestasCaballosPuesto.where(carrera_id: carrera_id, status: 3, status2: 6).each do |pro|
      bus_user = UsuariosTaquilla.find(pro.id_propone)
      next unless bus_user.usa_cajero_externo 
     
      if pro.id_propone == pro.id_juega
        tra_id = pro.tickets_detalle_id_juega
        ref_id = pro.reference_id_juega
      else
        tra_id = pro.tickets_detalle_id_banquea
        ref_id = pro.reference_id_banquea
      end
      descripcion = "Reverso/Eiminada"
      monto_t = pro.monto * bus_user.moneda_default_dolar.to_f
      array_cajero << { 'id' => bus_user.cliente_id, 'taq_id' => bus_user.id, 'transaction_id' => tra_id,
                        'reference_id' => ref_id, 'amount' => monto_t.to_f, 'details' => descripcion }
    end
    render json: { 'message' => 'No hay datos para enviar.' }, status: :unprocessable_entity and return if array_cajero.empty?

    PremiacionApiJob.perform_async array_cajero, hipodromo_id, carrera_id, tipo_id
    render json: { 'message' => 'OK' }

  end
end