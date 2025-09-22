# frozen_string_literal: true

# case generadora caballos
# rubocop: disable Metrics/ClassLength
class GenerarPropuestasCaballosJob
  include Sidekiq::Worker
  TIPOAPUESTA = {
    1 => ['1 P', '1'], 2 => ['1 y 2 N', '1'], 3 => ['2 N', '1'], 4 => ['2 y 2 N', '1'],
    5 => ['2 P', '1'], 6 => ['2 y 3 N', '1'], 7 => ['3 N', '1'], 8 => ['3 y 3 N', '1'],
    9 => ['3 P', '1'], 10 => ['3 y 4 N', '1'], 11 => ['4 N', '1'], 12 => ['4 y 4 N', '1'],
    13 => ['4 P', '1'], 14 => ['4 y 5 N', '1'], 15 => ['5 N', '1'], 16 => ['5 y 5 N', '1'],
    17 => ['5 P', '1'], 18 => ['P a P', '1'], 19 => ['10 a 9', '0.9'], 20 => ['10 a 8', '0.8'],
    21 => ['10 a 7', '0.7'], 22 => ['10 a 6', '0.6'], 23 => ['10 a 5', '0.5'], 24 => ['10 a 4', '0.4'],
    25 => ['10 a 3', '0.3'], 26 => ['10 a 2', '0.2']
  }.freeze
  # rubocop: enable Metrics/ClassLength

  # rubocop: disable Metrics/MethodLength
  # rubocop: disable Metrics/AbcSize
  def perform(usuario, propuestas)
    return if propuestas.count.zero?

    init_session(usuario)
    user = UsuariosTaquilla.find_by(correo: usuario[0])
    carrera = CaballosCarrera.find(propuestas[0]['caballo_id']).carrera
    return unless carrera.activo

    eliminar_propuestas_previas(user.id, carrera.id)

    hipodromo = carrera.jornada.hipodromo
    propuestas.each do |propuesta|
      banquea = propuesta['banquean']
      juega = propuesta['juegan']
      banquea_ml = convertir_logro_a_decimal(propuesta['banquean_ml']).round(2)
      juega_ml = convertir_logro_a_decimal(propuesta['juegan_ml']).round(2)
      monto = propuesta['monto']
      next if monto.to_f <= 0

      monto_propuesta = propuesta['monto_propuesta']
      caballo_id = propuesta['caballo_id']
      caballo = CaballosCarrera.find(caballo_id)
      texto = generar_text_jugada(hipodromo.nombre, carrera.numero_carrera, caballo.numero_puesto, caballo.nombre)
      enviar_propuesta(generar_data(caballo_id, monto, 2, banquea, carrera.id, 1, texto)) unless banquea.zero?
      enviar_propuesta(generar_data(caballo_id, monto, 1, juega, carrera.id, 1, texto)) unless juega.zero?
      enviar_propuesta_ml(user.id, generar_data_ml(caballo_id, monto, 2, banquea_ml, carrera.id, 1, texto, monto_propuesta)) unless banquea_ml.zero?
      enviar_propuesta_ml(user.id, generar_data_ml(caballo_id, monto, 1, juega_ml, carrera.id, 1, texto, monto_propuesta)) unless juega_ml.zero?
    end
  end
  # rubocop: enable Metrics/MethodLength
  # rubocop: enable Metrics/AbcSize

  def generar_text_jugada(nombre_hipodromo, carrera, numero_caballo, nombre_caballo)
    "#{nombre_hipodromo} | C#{carrera} | #{numero_caballo}-#{nombre_caballo}"
  end

  # rubocop: disable Metrics/MethodLength
  def generar_data(caballo_id, monto, accion, tipo, carrera_id, moneda, texto)
    {
      'tomo' => false,
      'id' => caballo_id.to_i,
      'jugada' => texto,
      'monto' => monto.to_f,
      'accion' => accion.to_i,
      'tipo' => tipo.to_i,
      'nombre_tipo' => TIPOAPUESTA[tipo][0],
      'monto_tipo' => TIPOAPUESTA[tipo][1].to_f,
      'carrera_id' => carrera_id.to_i,
      'moneda' => moneda.to_i,
      'acc_nombre' => accion.to_i == 1 ? 'Jugo' : 'Banqueo'
    }
  end
  # rubocop: enable Metrics/MethodLength

  # rubocop: disable Metrics/MethodLength
  # rubocop: disable Metrics/ParameterLists
  def generar_data_ml(caballo_id, monto, accion, tipo, carrera_id, moneda, texto, monto_propuesta)
    caballo = CaballosCarrera.find(caballo_id.to_i)
    {
      'puesto' => caballo.numero_puesto,
      'tomar' => false,
      'tipo' => 1,
      'tipo_nombre' => 'Ganador',
      'nombre_equipo' => caballo.nombre,
      'carrera_id' => carrera_id.to_i,
      'caballo_id' => caballo_id.to_i,
      'nombre_caballo' => caballo.nombre,
      'logro' => tipo,
      'monto' => (accion.to_i == 1 ? monto_propuesta.to_f : monto.to_f).to_s,
      'accion' => accion.to_i,
      'deporte_id' => 0,
      'altabaja_jugada' => 0,
      'acc_nombre' => accion.to_i == 1 ? 'Jugo' : 'Banqueo',
      'jugada' => texto
    }
  end
  # rubocop: enable Metrics/MethodLength
  # rubocop: enable Metrics/ParameterLists

  def init_session(usuario)
    @agent = Mechanize.new
    params = { correo: usuario[0], password: usuario[1] }
    @agent.post("#{ENV['taquilla_url']}login/procesar", params)
  end

  # rubocop: disable Metrics/MethodLength
  def eliminar_propuestas_previas(id, carrera_id)
    data = []
    propuestas = PropuestasCaballosPuesto.where(id_propone: id, status: 1, activa: true, carrera_id: carrera_id)
    propuestas.each do |propuesta|
      data << "#{propuesta.id}-3"
    end

    propuestas_ml = PropuestasCaballo.where(id_propone: id, status: 1, activa: true, carrera_id: carrera_id)
    propuestas_ml.each do |propuesta|
      data << "#{propuesta.id}-2"
    end
    return unless data.count.positive?

    header = { 'Content-Type' => 'application/json' }
    data_general = { user_id: id, data: data, idioma: 'es', tipo_logro: 'us' }.to_json
    @agent.post("#{ENV['taquilla_url']}/apuestas/eliminar_propuestas", data_general, header)
  end
  # rubocop: enable Metrics/MethodLength

  def enviar_propuesta(parametros)
    header = { 'Content-Type' => 'application/json' }
    @agent.post("#{ENV['taquilla_url']}apuestas_caballo_puestos/crear_apuesta", parametros.to_json, header)
  end

  def enviar_propuesta_ml(id, parametros)
    header = { 'Content-Type' => 'application/json' }
    data_general = { user_id: id, data: parametros, data_sport: { tipo_logro: 'us', logro: parametros['logro'] } }.to_json
    @agent.post("#{ENV['taquilla_url']}apuestas_caballo/crear_apuesta", data_general, header)
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
