module Unica
  class CarrerasController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :seguridad_cuentas, only: [:index]
    include ApplicationHelper

    def suspender
      @hipodromos = Hipodromo.where(activo: true).order(:nombre)
    end

    def buscar_jornadas
      jornadas = Jornada.where(hipodromo_id: params[:id].to_i, fecha: (Time.now - 1.day).beginning_of_day..(Time.now + 5.days)).order(:fecha)
      if jornadas.present?
        render json: { "jornadas" => jornadas }, methods: [:fecha_bonita]
      else
        render json: { "status" => "FAILD" }, status: 400
      end
    end

    def buscar_caballos
      buscar_premio = PremiosIngresado.where(carrera_id: params[:id])
      if buscar_premio.present?
        render json: { 'status' => 'FAILD', 'msg' => 'Carrera fue Premiada' }, status: 400
        return
      end
      caballos = CaballosCarrera.where(carrera_id: params[:id]).order(:id)
      buscar_carrera = Carrera.find(params[:id])
      count_caballos = CaballosCarrera.where(carrera_id: params[:id]).count
      count_retirados = CaballosCarrera.where(carrera_id: params[:id], retirado: true).count
      if buscar_carrera.activo == false && count_caballos == count_retirados
        render json: { 'status' => 'FAILD', 'msg' => 'Carrera ya fue suspendida' }, status: 400
        return
      end
      @a1 = false
      @x1 = false
      @b2 = false
      @x2 = false
      if caballos.present?
        caballos.each { |buscab|
          if buscab.numero_puesto == "1A"
            @a1 = true
          end
          if buscab.numero_puesto == "1X"
            @x1 = true
          end
          if buscab.numero_puesto == "2B"
            @b2 = true
          end
          if buscab.numero_puesto == "2X"
            @x2 = true
          end
        }
        carrera = Carrera.find(params[:id])
        render json: { "status" => "OK", "cantidad" => caballos.last.numero_puesto, "hora" => carrera.hora_carrera[0, 5], "a1" => @a1, "x1" => @x1, "b2" => @b2, "x2" => @x2 }
      else
        render json: { "status" => "FAILD" }
      end
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
        caballos.each do |ca|
          @caballos_array << { 'numero_puesto' => ca.numero_puesto, 'nombre' => ca.nombre, 'retirado' => ca.retirado }
          cantidad_total = ca.numero_puesto
        end
      else
        render json: { 'status' => 'FAILD' }, status: 400
      end
      render partial: 'unica/carreras/caballos', layout: false
    end

    def buscar_carreras
      cantidad_carreras = Carrera.where(jornada_id: params[:id].to_i,
                                        id: CaballosCarrera.where(carrera_id: Carrera.where(jornada_id: params[:id].to_i).pluck(:id)).pluck(:carrera_id)).order(:id).pluck(:numero_carrera)
      carreras = Carrera.where(jornada_id: params[:id].to_i).order(:id)
      premios = PremiosIngresado.where(jornada_id: params[:id].to_i).to_a
      carreras = carreras.each do |car|
        bus = premios.select { |item| item['carrera_id'].to_i == car.id }
        car.numero_carrera = car.numero_carrera + ' Premiada' if bus.present?
      end
      if carreras.present?
        render json: { 'carreras' => carreras, 'cantidad_carreras' => cantidad_carreras }
      else
        render json: { 'status' => 'FAILD' }, status: 400
      end
    end

    def suspender_carrera
      carrera_id = params[:id]
      todos_caballos_nombre = true
      arreglo_enjuego = []
      arreglo_propuestas = []
      hipodromo = Carrera.find(carrera_id).jornada.hipodromo
      carrera_actual = Carrera.find(carrera_id)
      Servicios::Carreras.new.cerrar(carrera_id, session[:usuario_actual]['id'],  false)
      buscar_caballos = carrera_actual.caballos_carrera
      caballos = []
      buscar_caballos.each do |caballo|
        caballos << { 'id' => caballo.numero_puesto, 'nombre' => caballo.nombre, 'retirado' => true }
      end
      # actualizar_propuestas_no_enjuego(buscar_caballos)

      cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_id).count - caballos.count
      retirar_tipo = []
      retirados_propuestas = []
      retirados_enjuego = []
      @retirar_array_cajero = []
      @nojuega_array_cajero = []
      @usuarios_interno_ganan = []

      @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
      @ids_cajero_externop =  ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json
    
     #@todos_ids = ActiveRecord::Base.connection.execute('select id,(select factor_cambios.valor_dolar from factor_cambios where factor_cambios.cobrador_id > 0 and factor_cambios.grupo_id = usuarios_taquillas.grupo_id and factor_cambios.cobrador_id = usuarios_taquillas.cobrador_id and factor_cambios.moneda_id = usuarios_taquillas.moneda_default) as valor_moneda from usuarios_taquillas').as_json
     #@ids_cajero_externop = ActiveRecord::Base.connection.execute('select id,cliente_id, (select factor_cambios.valor_dolar from factor_cambios where factor_cambios.grupo_id = usuarios_taquillas.grupo_id and factor_cambios.cobrador_id = usuarios_taquillas.cobrador_id and factor_cambios.moneda_id = usuarios_taquillas.moneda_default) as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json

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
        ActiveRecord::Base.transaction do
          if caballos.count > 0
            caballos.each do |cab|
              if cab['retirado']
                id_retirado = ActiveRecord::Base.connection.execute("update caballos_carreras set updated_at = now(), retirado = true where carrera_id = #{carrera_id} and numero_puesto = '#{cab['id']}' returning id")
                sleep 1
                buscar = CaballosCarrera.find_by(id: id_retirado[0]['id'])
              else
                buscar = CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab['id'])
              end
              if buscar.present?
                if cab['retirado']
                  bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo.id,
                                                                          carrera_id: carr.id, caballos_carrera_id: buscar.id)
                  bus_cab_ret_api.update(status: 2, user_id: session[:usuario_actual]['id']) if bus_cab_ret_api.present?
                  ActionCable.server.broadcast 'publicas_deporte_channel', {
                                               data: { 'tipo' => 'RETIRAR_CABALLOS', 'id' => buscar.id.to_i }}
                  enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: buscar.id, status: [1, 2])
                  if enjuego.present?
                    enjuego.each do |enj|
                      if enj.status == 1
                        # OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
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
                                         enj.monto.to_f, 'Devolucion/Retirado')
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
                        # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                        # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                        busca_user = buscar_cliente_cajero(id_quien_juega)
                        if busca_user != '0'
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega,
                                         cuanto_juega.to_f, 'Devolucion/Retirado')
                        end
                        busca_user = buscar_cliente_cajero(id_quien_banquea)
                        if busca_user != '0'
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea,
                                         monto_banqueado.to_f, 'Devolucion/Retirado')
                        end
                      end
                    end
                    enjuego.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
                  end
                  if retirar_tipo.length.positive?
                    enjuego = PropuestasCaballosPuesto.where(carrera_id: carrera_id, activa: false, status: 2,
                                                             tipo_apuesta_id: retirar_tipo)
                    if enjuego.present?
                      enjuego.each do |enj|
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.status == 1
                          # OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone,
                          #                          descripcion: "No entra en juego: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          busca_user = buscar_cliente_cajero(id_propone)
                          if busca_user != '0'
                            if enj.id_propone == enj.id_juega
                              tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                              reference_id_propone = enj.reference_id_juega
                            else
                              tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                              reference_id_propone = enj.reference_id_banquea
                            end
                            set_envios_api(5, busca_user, tickets_detalle_id_propone, reference_id_propone,
                                           enj.monto.to_f, 'No en tra en juego')
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
                          # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                          #                          descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                          #                          descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
                          busca_user = buscar_cliente_cajero(id_quien_juega)
                          if busca_user != '0'
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega,
                                           cuanto_juega.to_f, 'No entra en juego')
                          end
                          busca_user = buscar_cliente_cajero(id_quien_banquea)
                          if busca_user != '0'
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea,
                                           monto_banqueado.to_f, 'No entra en juego')
                          end
                        end
                      end
                      enjuego.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
                    end
                  end
                  enjuego = PropuestasCaballo.where(caballos_carrera_id: buscar.id, status: [1, 2])
                  if enjuego.present?
                    enjuego.each do |enj|
                      if enj.status == 1
                        # OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
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
                                         enj.monto.to_f, 'Devolucion/Retirado')
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
                        # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                        # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                        #                          descripcion: "Reverso/Retirado: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                        busca_user = buscar_cliente_cajero(id_quien_juega)
                        if busca_user != '0'
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega,
                                         cuanto_juega.to_f, 'Devolucion/Retirado')
                        end
                        busca_user = buscar_cliente_cajero(id_quien_banquea)
                        if busca_user != '0'
                          set_envios_api(3, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea,
                                         monto_banqueado.to_f, 'Devolucion/Retirado')
                        end
                      end
                    end
                    enjuego.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
                  end
                  if retirar_tipo.length.positive?
                    enjuego = PropuestasCaballo.where(carrera_id: carrera_id, activa: false, status: 2,
                                                      tipo_apuesta_id: retirar_tipo)
                    if enjuego.present?
                      enjuego.each do |enj|
                        id_quien_juega = enj.id_juega
                        id_quien_banquea = enj.id_banquea
                        if enj.status == 1
                          # OperacionesCajero.create(usuarios_taquilla_id: enj.id_propone,
                          #                          descripcion: "No entra en juego: #{enj.texto_jugada}", monto: monto_local(enj.id_propone, enj.monto.to_f), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          busca_user = buscar_cliente_cajero(id_propone)
                          if busca_user != '0'
                            if enj.id_propone == enj.id_juega
                              tickets_detalle_id_propone = enj.tickets_detalle_id_juega
                              reference_id_propone = enj.reference_id_juega
                            else
                              tickets_detalle_id_propone = enj.tickets_detalle_id_banquea
                              reference_id_propone = enj.reference_id_banquea
                            end
                            set_envios_api(5, busca_user, tickets_detalle_id_propone, reference_id_propone,
                                           enj.monto.to_f, 'No en tra en juego')
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
                          # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                          #                          descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_juega, cuanto_juega), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                          #                          descripcion: "No entra en Juego: #{enj.texto_jugada}", monto: monto_local(id_quien_banquea, monto_banqueado), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
                          busca_user = buscar_cliente_cajero(id_quien_juega)
                          if busca_user != '0'
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega,
                                           cuanto_juega.to_f, 'No entra en juego')
                          end
                          busca_user = buscar_cliente_cajero(id_quien_banquea)
                          if busca_user != '0'
                            set_envios_api(5, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea,
                                           monto_banqueado.to_f, 'No entra en juego')
                          end
                        end
                      end
                      enjuego.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
                    end
                  end
                elsif (cab['retirado'] == false) && buscar.retirado
                  buscar.update(retirado: false)
                end
              end
            end
            ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS',
                                                                             'id' => carrera_id }}

            # actualiza saldo para los usuarios internos de unpuesto
            update_saldos_taquilla(@usuarios_interno_ganan) if @usuarios_interno_ganan.length.positive?
            render json: { 'status' => 'OK' } unless params[:es_interno].present?
            if @retirar_array_cajero.length.positive?
              PremiacionApiJob.perform_async @retirar_array_cajero, hipodromo.id, carrera_id, 3
            end
            if @nojuega_array_cajero.length.positive?
              PremiacionApiJob.perform_async @nojuega_array_cajero, hipodromo.id, carrera_id, 5
            end
          else
            unless params[:es_interno].present?
              render json: { 'status' => 'FAIL', 'msg' => 'No hay caballos para esta carrera.' }, status: 400 and return
            end
          end
        end
      rescue StandardError => e
        logger.info('***************************************************')
        logger.info(e.message)
        logger.info('***************************************************')
        logger.info(e.backtrace.inspect)
        logger.info('***************************************************')
        puts e.message
        puts e.backtrace.inspect
        unless params[:es_interno].present?
          render json: { 'status' => 'FAIL', 'msg' => 'Revise todos los datos.' }, status: 400 and return
        end
      end
    end


    def actualizar_propuestas_no_enjuego(caballos)
      ids = caballos.ids
      retirar = PropuestasCaballosPuesto.where(caballos_carrera_id: ids).where.not(status: [1, 2])
      retirar.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
    end


    def retirar_pendientes
      ActiveRecord::Base.transaction do
        datos = params[:data]
        datos.each do |dat|
          CaballosRetiradosConfirmacion.find_by(hipodromo_id: dat['hid'], carrera_id: dat['carr_id'], caballos_carrera_id: dat['cab_id']).update(
            status: 2, user_id: session[:usuario_actual]['id']
          )
        end
        datos_agrupados = datos.group_by { |d| d['carr_id'] }
        datos_agrupados.each do |dat, value|
          params[:id] = dat
          params[:caballos] = value
          params[:es_interno] = true
          retirar
        end
        render json: { 'status' => 'OK' }
      end
    rescue StandardError
      render json: { 'status' => 'FAILD' }, status: 400
    end
  end
end
