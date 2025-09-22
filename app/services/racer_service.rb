# frozen_string_literal: true

module RacerService
  # clase para cerrar carrera
  class Racer
    include ApplicationHelper
    # rubocop:disable all
    def close_racer(hipodromo_id_buscar, id_carrera)
      @cierrec_array_cajero = []
      @usuarios_interno_ganan = []
      @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
      @ids_cajero_externop = ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json
      ids_upadted = ActiveRecord::Base.connection.execute("update propuestas_caballos_puestos set activa = false, status = 4, status2 = 7, updated_at = now() where carrera_id = #{id_carrera} and activa = true and status = 1 returning id")
      prupuestas = PropuestasCaballosPuesto.where(id: ids_upadted.pluck('id'))
      if prupuestas.present?
        prupuestas.each do |prop|
          if prop.id_propone == prop.id_juega
            tra_id = prop.tickets_detalle_id_juega
            ref_id = prop.reference_id_juega
          else
            tra_id = prop.tickets_detalle_id_banquea
            ref_id = prop.reference_id_banquea
          end
          descripcion = "Reverso/No igualada #{prop.texto_jugada}"
          # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
          #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
          busca_user = buscar_cliente_cajero(prop.id_propone)
          if busca_user != '0'
            set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualada')
          end
        end
      end

      ids_upadted = ActiveRecord::Base.connection.execute("update propuestas_caballos set activa = false, status = 4, status2 = 7, updated_at = now() where carrera_id = #{id_carrera} and activa = true and status = 1 returning id")
      prupuestas_logros = PropuestasCaballo.where(id: ids_upadted.pluck('id'))
      if prupuestas_logros.present?
        prupuestas_logros.each do |prop|
          if prop.id_propone == prop.id_juega
            tra_id = prop.tickets_detalle_id_juega
            ref_id = prop.reference_id_juega
          else
            tra_id = prop.tickets_detalle_id_banquea
            ref_id = prop.reference_id_banquea
          end
          descripcion = "Reverso/No igualada #{prop.texto_jugada}"
          # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
          #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
          busca_user = buscar_cliente_cajero(prop.id_propone)
          if busca_user != '0'
            set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualada')
          end
        end
      end
      PremiacionApiJob.perform_async @cierrec_array_cajero, hipodromo_id_buscar, id_carrera, 4
    end
    # rubocop:enable all
  end
end
