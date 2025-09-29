module Unica
  class RetiradosController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :seguridad_cuentas, only: [:index]
    include ApplicationHelper

    def index
      @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id),
                                    activo: true).order(:nombre)
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
      render partial: 'retirados/caballos', layout: false
    end

    def buscar_carreras
      cantidad_carreras = Carrera.where(activo: true, jornada_id: params[:id].to_i,
                                        id: CaballosCarrera.where(carrera_id: Carrera.where(jornada_id: params[:id].to_i).pluck(:id)).pluck(:carrera_id)).order(:id).pluck(:numero_carrera)
      carreras = Carrera.where(activo: true, jornada_id: params[:id].to_i).order(:id)
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

    def send_retirar_sistemas(url, carrera_id, id_api, data_send)
      uri = URI.parse(url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
      req.body = { 'id' => carrera_id, 'id_api' => id_api, 'caballos' => data_send, 'premia_api' => true }.to_json
      https.request(req)
    rescue StandardError => e
      puts e
    end

    # def envios_a_sistemas(carrera_id, id_api, data_send)
    #   sistemas = ["https://admin.betsolutionsgroup.com/unica/retirados/retirar",
    #               "https://admin.tablasdinamica.com/unica/retirados/retirar",
    #               "https://admin.rojosynegros.com/unica/retirados/retirar",
    #               "https://admin.piramidehipica.com/unica/retirados/retirar"]
    #   sistemas.each do |sis_url|
    #     Thread.new { 
    #       send_retirar_sistemas(sis_url, carrera_id, id_api, data_send)
    #     }
    #   end
    # end

    def retirar_manual
      carrera = Carrera.find(params[:id].to_i)
      send_to_api(carrera.id, carrera.id_api, params[:caballos])
      render json: { status: 'OK'}
    end

    def retirar
      caballos = params[:caballos]
      todos_caballos_nombre = true
      arreglo_enjuego = []
      arreglo_propuestas = []
      search_carrera = if params[:id_api].present?
                         Carrera.find_by(id_api: params[:id_api])
                       else
                         Carrera.find(params[:id].to_i)
                       end
      return unless search_carrera.present?                 

      carrera_id = search_carrera.id

      hipodromo = search_carrera.jornada.hipodromo
      cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_id).count - caballos.select do |cab|
                                                                                                   cab['retirado'] == true
                                                                                                 end.count
      # if ENV['reenvia_apis'] == 'SI'
      #   unless params[:premia_api].present?
      #     envios_a_sistemas(carrera_id, search_carrera.id_api, caballos)
      #   end
      # end
      
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
                # actualizar_propuestas_no_enjuego(id_retirado[0]['id'])
                buscar = CaballosCarrera.find_by(id: id_retirado[0]['id'])
              else
                buscar = CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab['id'])
              end
              if buscar.present?
                if cab['retirado']
                  bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo.id,
                                                                          carrera_id: carr.id, caballos_carrera_id: buscar.id)
                  user_ing = session[:usuario_actual].present? ? session[:usuario_actual]['id'] : User.first.id                                                                         
                  bus_cab_ret_api.update(status: 2, user_id: user_ing) if bus_cab_ret_api.present?
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
            # actualiza saldo para los usuarios internos de unpuesto
            # update_saldos_taquilla(@usuarios_interno_ganan) if @usuarios_interno_ganan.length.positive?
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

    def actualizar_propuestas_no_enjuego(cab_id)
      retirar = PropuestasCaballosPuesto.where(caballos_carrera_id: cab_id).where.not(status: [1, 2, 3, -1])
      retirar.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
    end

    def send_to_api(carrera_id, id_api, data_send)
      uri = URI.parse('https://admin-puesto.aposta2.com/api/retirar_interno')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
      req.body = { 'id' => carrera_id, 'id_api' => id_api, 'caballos' => data_send, 'premia_api' => true, 'recibe_puestos' => true }.to_json
      https.request(req)
    rescue StandardError => e
      puts e
    end

    def retirados_pendiente
      @prem_pend = PremioasIngresadosApi.where(created_at: Time.now.all_day, status: 1)
                                        .where("NOT EXISTS (
                                          SELECT 1 FROM premios_ingresados 
                                          WHERE premios_ingresados.hipodromo_id = premioas_ingresados_apis.hipodromo_id 
                                          AND premios_ingresados.carrera_id = premioas_ingresados_apis.carrera_id
                                        )")
    end

    def retirar_pendientes
      ActiveRecord::Base.transaction do
        datos = params[:data]
        datos.each do |dat|
          buscab = CaballosRetiradosConfirmacion.find_by(hipodromo_id: dat['hid'], carrera_id: dat['carr_id'], caballos_carrera_id: dat['cab_id'])
          buscab.update(status: 2, user_id: session[:usuario_actual]['id'] )
        end
        datos_agrupados = datos.group_by { |d| d['carr_id'] }
        datos_agrupados.each do |dat, value|
          bus_carrera = Carrera.find_by(id: dat)
          send_to_api(bus_carrera.id, bus_carrera.id_api, value)
        end
        render json: { 'status' => 'OK' }
      end
    rescue StandardError
      render json: { 'status' => 'FAILD' }, status: 400
    end
  end
end
