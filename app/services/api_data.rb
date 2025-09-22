module ApiData
  # 1- Premiar
  # 3- Retirar caballos
  # 4- cerrar_carrera
  # 5- No entra en juego

  class Server
    include ApiHelper
    def self.send_data(data_premio, hipodromo_id, carrera_id, tipo)
      ids_integrador = Integrador.ids
      return unless ids_integrador.present?

      datos_carrera = ''
      ids_integrador.each do |idi|
        all_users = UsuariosTaquilla.select(:id, :cliente_id).where(integrador_id: idi, usa_cajero_externo: true)
        usuarios_ids = all_users.map(&:cliente_id)
        ids_taq = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:id)
        user_array = []
        datos_carrera = "#{Hipodromo.find(hipodromo_id).nombre} Carrera #{Carrera.find(carrera_id).numero_carrera}"

        data_premio.each do |prop|
          if usuarios_ids.include?(prop['id']) && ids_taq.include?(prop['taq_id'].to_i)
            user_array << { 'id' => prop['id'], 'transaction_id' => prop['transaction_id'], 'reference_id' => prop['reference_id'], 
                            'amount' => prop['amount'].to_f, 'details' => prop['details'], 'pay_amount' => prop['pay_amount'].to_f, 
                            'loser' => prop['loser'] }
          end
        end
        losers = tipo.to_i == 1 ? generate_losers(carrera_id, ids_taq, all_users) : []
        next if user_array.length.zero? && losers.length.zero?

        objeto_completo = { "type": tipo, "description": datos_carrera, "users": user_array, "losers": tipo.to_i == 1 ? losers : [] }
        acreditar_saldos_cajero_externo(idi, objeto_completo, hipodromo_id, carrera_id, tipo)
      end
    end

    def self.generate_losers(carrera_id, ids_taq, all_users)
      sleep 5
      ids_losers = PropuestasCaballosPuesto.where(carrera_id: carrera_id)
                                           .where(id_pierde: ids_taq)
      all_losers = []
      ids_losers.each do |los|
        tra_id = nil
        ref_id = nil
        cuanto_pierde = 0
        cuanto_gana = 0
        detalle = los.texto_jugada
        id_temp_loser = all_users.find { |a| a['id'] == los.id_pierde }.cliente_id
        if los.id_juega == los.id_pierde
          tra_id = los.tickets_detalle_id_juega
          ref_id = los.reference_id_juega
          detalle = "Jugó #{detalle}"
        else
          tra_id = los.tickets_detalle_id_banquea
          ref_id = los.reference_id_banquea
          detalle = "Banqueó #{detalle}"
        end

        if los.id_propone == los.id_pierde
          cuanto_gana = los.monto.to_f
        else
          cuanto_gana = los.cuanto_gana_completo.to_f
        end
        usrc = UsuariosTaquilla.find_by(id: los.id_gana)
        usrc_los = UsuariosTaquilla.find_by(id: los.id_pierde)
        # comis = (((cuanto_gana.to_f * usrc.comision) / 100) / 2) * usrc.simbolo_moneda_default
        cuento_pierde = cuanto_gana.to_f * usrc_los.moneda_default_dolar
        win = "#{usrc.cobrador_id}-#{usrc.cliente_id}"
        all_losers << { 'id' => id_temp_loser, 'transaction_id' => tra_id, 'reference_id' => ref_id, 'amount' => 0, 'details' => detalle,
                        'pay_amount' => cuento_pierde.to_f.round(4), 'winner' =>  win }
      end
      all_losers
    end
  end
end


