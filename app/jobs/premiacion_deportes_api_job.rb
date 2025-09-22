class PremiacionDeportesApiJob 
  include ApiHelper
  include Sidekiq::Worker

  def perform(data_premio,liga_id, match_id,tipo)
      ids_integrador = Integrador.ids
      if ids_integrador.present?
        datos_juego = ""
        ids_integrador.each { |idi|
          usuarios_ids = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:cliente_id)
          ids_taq = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:id)
          user_array = []
          datos_juego = Match.find(match_id).detalle_match

          data_premio.each { |prop|
            if usuarios_ids.include?(prop["id"]) and ids_taq.include?(prop["taq_id"].to_i) 
              user_array <<  { "id" => prop["id"], "transaction_id" => prop["transaction_id"], "reference_id" => prop["reference_id"], "amount" => prop["amount"], "details" => prop["details"] }
            end            
          }
          objeto_completo = { "type": tipo, "description": datos_juego, "users": user_array }
          if user_array.length > 0
            acreditar_saldos_cajero_externo_deporte(idi, objeto_completo,liga_id, match_id,tipo)
          end
        }
      end
  end
end
