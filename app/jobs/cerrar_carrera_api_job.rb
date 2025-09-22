class CerrarCarreraApiJob 
  #< ApplicationJob
  include ApiHelper
  include Sidekiq::Worker

#  queue_as :default

  def perform(args,hipodromo_id, carrera_id)
    if args.length > 0
      ids_integrador = Integrador.ids
      if ids_integrador.present?
        datos_carrera = ""
        ids_integrador.each { |idi|
          usuarios_ids = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:id)
          propuestas = Propuesta.where(id: args, usuarios_taquilla_id: usuarios_ids)
          user_array = []
          if propuestas.present?
            datos_carrera = propuestas[0].nombre_hipodromo_largo + " Carrera " + propuestas[0].nombre_carrera
          end
          propuestas.each { |prop|
            detalle = prop.accion_id == 1 ? prop.jugada_completa_jugar_api : prop.jugada_completa_banquear_api
            user = prop.usuarios_taquilla
            #ticket = TicketsDetalle.find_by(propuesta_id: id_operacion)
            user_array << {
              "id" => user.cliente_id,
              "transaction_id" => prop.tickets_detalle_id,
              "reference_id" => prop.id,
              "amount" => prop.monto,
              "details" => detalle,
            }
          }
          objeto_completo = { "type": 4, "description": datos_carrera, "users": user_array }
          if user_array.length > 0
            begin 
               acreditar_saldos_cajero_externo(idi, objeto_completo,hipodromo_id, carrera_id,4)
            rescue  
            end
          end
        }
      end
    end
  end
end
