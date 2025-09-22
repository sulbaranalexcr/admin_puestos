def retirar(carrera_id, caballos)
  hipodromo = Carrera.find(carrera_id).jornada.hipodromo
  cantidad_caballos = CaballosCarrera.where(carrera_id: Carrera.find(carrera_id).id).count - caballos.select do |cab|
                                                                                               cab['retirado'] == true
                                                                                             end.count
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
          next unless CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: cab['id']).present?

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
        # actualiza saldo para los usuarios internos de unpuesto
        if @retirar_array_cajero.length.positive?
          PremiacionApiJob.perform_async @retirar_array_cajero, hipodromo.id, carrera_id, 3
        end
        if @nojuega_array_cajero.length.positive?
          PremiacionApiJob.perform_async @nojuega_array_cajero, hipodromo.id, carrera_id, 5
        end
      end
    end
  rescue StandardError => e
    Rails.logger.info('***************************************************')
    Rails.logger.info(e.message)
    Rails.logger.info('***************************************************')
    Rails.logger.info(e.backtrace.inspect)
    Rails.logger.info('***************************************************')
  end
end

def actualizar_propuestas_no_enjuego(cab_id)
  retirar = PropuestasCaballosPuesto.where(caballos_carrera_id: cab_id).where.not(status: [1, 2])
  retirar.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
end
