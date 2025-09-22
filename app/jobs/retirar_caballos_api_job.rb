class RetirarCaballosApiJob
  include ApiHelper
  include Sidekiq::Worker

  def perform(args, hipodromo_id, carrera_id)
    return unless args[0].length.positive? || args[1].length.positive?

    ids_integrador = Integrador.ids
    return unless ids_integrador.present?

    datos_carrera = ''
    ids_integrador.each do |idi|
      usuarios_ids = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:id)
      propuestas = Propuesta.where(id: args[0], usuarios_taquilla_id: usuarios_ids)
      user_array = []
      if propuestas.present?
        datos_carrera = "#{propuestas[0].nombre_hipodromo_largo} Carrera #{propuestas[0].nombre_carrera}"
      end
      propuestas.each do |prop|
        detalle = prop.accion_id == 1 ? prop.jugada_completa_jugar : prop.jugada_completa_banquear
        user = prop.usuarios_taquilla

        user_array << {
          'id' => user.cliente_id,
          'transaction_id' => prop.tickets_detalle_id,
          'reference_id' => prop.id,
          'amount' => prop.monto,
          'details' => detalle
        }
      end
      propuestas_enjuego = Enjuego.where(id: args[1], usuarios_taquilla_id: usuarios_ids)
      propuestas_enjuego.each do |prop|
        detalle = prop.propuesta.accion_id == 2 ? prop.propuesta.jugada_completa_jugar_api : prop.propuesta.jugada_completa_banquear_api
        user = prop.usuarios_taquilla

        user_array << {
          'id' => user.cliente_id,
          'transaction_id' => prop.tickets_detalle_id,
          'reference_id' => prop.id,
          'amount' => prop.propuesta.monto_gana_completo,
          'details' => detalle
        }
      end
      objeto_completo = { "type": 3, "description": datos_carrera, "users": user_array }
      acreditar_saldos_cajero_externo(idi, objeto_completo, hipodromo_id, carrera_id, 3) if user_array.length > 0
    end
  end
end
