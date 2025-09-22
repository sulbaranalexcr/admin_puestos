# frozen_string_literal: true

module PropuestasParaDeportes
  class Crear
    def self.propuestas(match_id, deporte_id, tipo_job)
      propuestas = []
      usuarios = UsuariosGenerador.all
      busca_match = Match.find(match_id)
      return unless busca_match.liga.activo && busca_match.activo

      jugadas(match_id, deporte_id).each do |jugada|
        logro = convertir_logro_a_decimal(jugada[:logro].to_f)
        monto = MontosGeneradorPropuesta.last.monto(jugada[:deporte_id].to_i, jugada[:tipo].to_i)
        tipo = jugada[:tipo]
        banquean_ml, juegan_ml, monto_apuesta = ParametrosPropuestasDeporte::Condiciones.propuestas(logro, deporte_id, tipo, monto)
        propuestas << jugada.merge({ banquean_ml: banquean_ml, juegan_ml: juegan_ml, monto: monto, monto_propuesta: monto_apuesta })
      end
      return if propuestas.blank?

      usuarios.each do |usuario|
        user_job = { 'correo' => usuario.correo, 'clave' => usuario.clave, 'porcentaje' => usuario.porcentaje }
        GenerarPropuestasDeporteJob.perform_async(user_job, propuestas) if usuario.can_send
      end
    end

    def self.jugadas(match_id, deporte_id)
      jugadas = []
      busca_match = Match.find_by(id: match_id, local: Time.now.all_day)
      return [] unless busca_match.present?

      data = JSON.parse(busca_match.data)

      return [] unless data['money_line'].count.positive? && data['money_line'].key?('c')

      money_line = data['money_line']['c']
      data_mls = if deporte_id == 12
                   money_line
                 else
                   [money_line.select { |a| a['o'] < 2 }.min_by { |b| b['o'] }]
                 end
      if data_mls.present?
        data_mls.each do |data_ml|
          jugadas << {
            deporte_id: deporte_id,
            tipo: 1,
            match_id: match_id,
            equipo_id: data_ml['i'],
            nombre_equipo: data_ml['t'],
            equipo_contra: extract_equipo_contra(money_line, data_ml['i']),
            logro: data_ml['o'].to_f,
            hcap: 0,
            dadas: 0,
            altabaja_jugada: 0,
            texto_jugada: "Money Line | #{data_ml['t']} ",
            tipo_alta: 0
          }
        end
      end

      if data['run_line'].count.positive? && data['run_line'].key?('c')
        run_line = data['run_line']['c']
        data_rl = run_line.select { |a| a['o'] < 2 }.min_by { |b| b['o'] }

        if data_rl.present?
          nombre_rl = data_rl['t'].partition(/^*\(/)[0].squish
          indice = data['run_line']['c'].index { |a| a['i'] == data_rl['i'] }
          codigo_money_line = data['money_line']['c'][indice]['i']
          jugadas << {
            deporte_id: deporte_id,
            tipo: 2,
            match_id: match_id,
            equipo_id: codigo_money_line,
            nombre_equipo: nombre_rl,
            equipo_contra: extract_equipo_contra(money_line, codigo_money_line),
            logro: data_rl['o'].to_f,
            hcap: data_rl['l'],
            dadas: data_rl['l'],
            altabaja_jugada: 0,
            texto_jugada: "Run Line | #{data_rl['t']} |",
            tipo_alta: 0
          }
        end
      end

      if data['alta_baja'].count.positive? && data['alta_baja'].key?('c')
        alta_baja = data['alta_baja']['c']
        data_ab = alta_baja.select { |a| a['o'] < 2 }.min_by { |b| b['o'] }
        nombre_ab = extra_equipo_id_ab(data_ab) == 1 ? 'Alta' : 'Baja'
        if data_ab.present?
          jugadas << {
            deporte_id: deporte_id,
            tipo: 3,
            match_id: match_id,
            equipo_id: extra_equipo_id_ab(data_ab),
            nombre_equipo: nombre_ab,
            equipo_contra: extra_equipo_id_ab(data_ab) == 1 ? 2 : 1,
            logro: data_ab['o'].to_f,
            hcap: 0,
            dadas: data_ab['l'],
            altabaja_jugada: 0,
            texto_jugada: "#{nombre_ab} | #{busca_match.nombre} |",
            tipo_alta: extra_equipo_id_ab(data_ab) == 1 ? 1 : 2
          }
        end
      end
      jugadas
    end

    def self.extra_equipo_id_ab(data)
      data['t'] =~ /over/i ? 1 : 2
    end

    def self.extract_equipo_contra(data, id)
      data.reject { |a| a['t'] =~ /draw/i }.pluck('i').reject { |b| b == id }[0]
    end

    def self.convertir_logro_a_decimal(logro)
      return 0 if logro.zero?

      if logro >= 2
        ((logro - 1) * 100).round
      else
        (-100 / (logro - 1)).round
      end
    end
  end
end

