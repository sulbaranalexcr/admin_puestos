# frozen_string_literal: true

# case generadora deportes
class GenerarPropuestasDeporteJob
  include Sidekiq::Worker

  # rubocop: disable Metrics/MethodLength
  # rubocop: disable Metrics/AbcSize
  def perform(usuario, propuestas)
    return if propuestas.count.zero?

    init_session(usuario)
    user = UsuariosTaquilla.find_by(correo: usuario['correo'])
    match = Match.find(propuestas[0]['match_id'])
    return unless match.local > '08:00'.to_time
    return unless match.activo
    return unless user.present?

    eliminar_propuestas_previas(user.id, propuestas[0]['match_id'])
    propuestas.each do |propuesta|
      liga_id = match.liga_id
      banquea_ml = propuesta['banquean_ml']
      juega_ml = propuesta['juegan_ml']
      monto = (propuesta['monto'].to_f * usuario['porcentaje']) / 100
      monto_propuesta = (propuesta['monto_propuesta'].to_f * usuario['porcentaje']) / 100
      next if monto.to_f <= 0

      match_id = propuesta['match_id']
      texto = propuesta['texto_jugada']
      equipo = {
        'equipo_id' => propuesta['equipo_id'],
        'equipo_contra' => propuesta['equipo_contra'],
        'nombre_equipo' => propuesta['nombre_equipo'],
        'hcap' => propuesta['hcap'],
        'dadas' => propuesta['dadas'],
        'altabaja_jugada' => propuesta['altabaja_jugada'],
        'deporte_id' => match.juego_id,
        'tipo_alta' => propuesta['tipo_alta']
      }
      enviar_propuesta_ml(user.id, generar_data_ml(propuesta['tipo'], match_id, monto, 2, banquea_ml, texto, monto_propuesta, equipo, liga_id)) unless banquea_ml.zero?
      enviar_propuesta_ml(user.id, generar_data_ml(propuesta['tipo'], match_id, monto, 1, juega_ml, texto, monto_propuesta, equipo, liga_id)) unless juega_ml.zero?
    end
  end
  # rubocop: enable Metrics/MethodLength
  # rubocop: enable Metrics/AbcSize

  # rubocop: disable Metrics/MethodLength
  # rubocop: disable Metrics/ParameterLists
  def generar_data_ml(tipo, match_id, monto, accion, logro, texto, monto_propuesta, equipo, liga_id)
    tipo_nombre = { 1 => 'Money Line', 2 => 'Run Line', 3 => 'Alta Baja' }
    {
      'tomar' => false,
      'tipo' => tipo,
      'tipo_nombre' => tipo_nombre[tipo],
      'match_id' => match_id,
      'liga_id' => liga_id,
      'equipo_id' => equipo['equipo_id'],
      'equipo_contra' => equipo['equipo_contra'],
      'nombre_equipo' => equipo['nombre_equipo'],
      'logro' => logro,
      'monto' => (accion.to_i == 1 ? monto_propuesta.to_f : monto.to_f).to_s,
      'hcap' => equipo['hcap'],
      'dadas' => equipo['dadas'],
      'accion' => accion.to_i,
      'deporte_id' => equipo['deporte_id'],
      'altabaja_jugada' => equipo['altabaja_jugada'],
      'acc_nombre' => accion.to_i == 1 ? 'Jugo' : 'Banqueo',
      'jugada' => texto,
      'tipo_alta' => equipo['tipo_alta']
    }
  end
  # rubocop: enable Metrics/MethodLength
  # rubocop: enable Metrics/ParameterLists

  def init_session(usuario)
    @agent = Mechanize.new
    params = { correo: usuario['correo'], password: usuario['clave'] }
    @agent.post("#{ENV['taquilla_url']}login/procesar", params)
  end

  def eliminar_propuestas_previas(id, match_id)
    data = []
    propuestas = PropuestasDeporte.where(id_propone: id, status: 1, activa: true, match_id: match_id)
    propuestas.each do |propuesta|
      data << "#{propuesta.id}-1"
    end
    return unless data.count.positive?

    header = { 'Content-Type' => 'application/json' }
    data_general = { user_id: id, data: data, idioma: 'es', tipo_logro: 'us' }.to_json
    @agent.post("#{ENV['taquilla_url']}/apuestas/eliminar_propuestas", data_general, header)
  end

  def enviar_propuesta_ml(id, parametros)
    header = { 'Content-Type' => 'application/json' }
    data_general = { user_id: id, data: parametros, data_sport: { tipo_logro: 'us', logro: parametros['logro'] } }.to_json
    @agent.post("#{ENV['taquilla_url']}apuestas/crear_apuesta", data_general, header)
  end

  def convertir_logro_a_decimal(logro)
    return 0 if logro.zero?

    if logro >= 2
      ((logro - 1) * 100).round
    else
      (-100 / (logro - 1)).round
    end
  end
end
