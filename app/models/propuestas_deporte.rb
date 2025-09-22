class PropuestasDeporte < ApplicationRecord
  include ApplicationHelper
  belongs_to :match
  belongs_to :operaciones_cajero, optional: true

  # , optional: true
  # validates :operaciones_cajero_id, presence: :false
  # before_commit :verificar_cajero

  def status_propuesta
    text_status2(status2)
  end

  def tipo_ticket(user_id)
    if id_juega.to_i == user_id.to_i
      'Jugo '
    else
      'Banqueo '
    end
  end

  def monto_ticket(user_id)
    if accion_id == 1
      monto.to_f
    else
      cuanto_gana_completo.to_f
    end
  end

  def status_propuesta_banca(user_id)
    if [8, 9].include?(status2.to_i)
      if id_gana.to_i == user_id
        'Gano'
      else
        'Perdio'
      end
    elsif [11, 12].include?(status2.to_i)
      if id_gana.to_i == user_id
        'Gano la Mitad'
      else
        'Perdio la Mitad'
      end
    else
      text_status2(status2)
    end
  end

  def usa_igual_accion
    true
  end

  def detalle_jugada
    mensaje = ''
    case tipo_apuesta
    when 1
      mensaje += ' Money Line '
      money_data = JSON.parse(match.data)['money_line']
      mensaje += money_data.present? ? money_data['c'].select { |bus| bus['i'] == equipo_id }[0]['t'] : ''
    when 2
      mensaje += ' Run Line/Spread '
      money_data = JSON.parse(match.data)['money_line']
      mensaje += money_data.present? ? money_data['c'].select { |bus| bus['i'] == equipo_id }[0]['t'] : ''
      mensaje += ' hcap ' + carreras_dadas.to_s
    when 3
      mensaje += tipo_altabaja == 1 ? ' Alta ' : ' Baja '
      matnom = match.nombre
      matnom = matnom.split(' v ')[0].split(' ')[0] + ' v ' + matnom.split(' v ')[1].split(' ')[0]
      mensaje += matnom
      mensaje += ' hcap ' + alta_baja.to_s
    end
    mensaje += ' Logro '
    mensaje += (logro > 0) && (logro != 100) ? ('+' + logro.to_i.to_s) : logro.to_i.to_s
  end

  def match_nombre
    json_data = JSON.parse(Match.find_by(match_id: match_id).match)
    if deporte_id.to_i == 12
      if json_data['c'][0]['c'][0]['i'].to_i == equipo_id.to_i
        'Empate'
      elsif json_data['c'][0]['c'][1]['i'].to_i == equipo_id.to_i
        json_data['c'][0]['c'][1]['t']
      elsif json_data['c'][0]['c'][2]['i'].to_i == equipo_id.to_i
        json_data['c'][0]['c'][2]['t']
      end
    elsif json_data['c'][0]['c'][0]['i'].to_i == equipo_id.to_i
      json_data['c'][0]['c'][0]['t']
    else
      json_data['c'][0]['c'][1]['t']
    end
  end

  def tipo_nombre
    case tipo_apuesta.to_i
    when 1
      'Money Line'
    when 2
      'Run Line/Spread'
    when 3
      if tipo_altabaja == 1
        'Alta'
      else
        'Baja'
      end
    end
  end

  def monto_reporte
    if accion_id.to_i == 1
      monto
    else
      cuanto_gana_completo
    end
  end

  def tipo_titulo(id_session)
    if accion_id == 1
      if id_juega == id_session
        'Jugo'
      else
        'Banqueo'
      end
    elsif id_banquea == id_session
      'Banqueo'
    else
      'Jugo'
    end
  end

  def hijas
    PropuestasDeporte.where(corte_id: id).order(:id) if status2 == 4
  end
end
