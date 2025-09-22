# frozen_string_literal: true

# clas para premiacion
class PremiarCaballosApiJob
  include ApiHelper
  include Sidekiq::Worker

  def perform(args)
    caballos = search_nyra_data(args['id'], args['carrera_id_nyra'])
    canti_llegadas = extract_results(caballos)
    if canti_llegadas.count.positive?
      prem = Unica::PremiacionPuestosController.new
      prem.params = ActionController::Parameters.new(args.merge(caballos: caballos))
      prem.premiar_puestos
    elsif args['cantidad_reintentar'].to_i > 3
      no_premiado(args['id'])
    else
      args['cantidad_reintentar'] = args['cantidad_reintentar'].to_i + 1
      un_minuto = Time.now + 1.minute
      PremiarCaballosApiJob.perform_at(un_minuto, args)
    end
  end

  def extract_results(caballos)
    caballos.select { |a| a['llegada'].positive? }
  end

  def no_premiado(carrera_id)
    carrera = Carrera.find(carrera_id)
    hipodromo = carrera.jornada.hipodromo
    buscar_api_pre = PremioasIngresadosApi.find_by(hipodromo_id: hipodromo.id, carrera_id: carrera.id)
    unless buscar_api_pre.present?
      buscar_api_pre = PremioasIngresadosApi.create(hipodromo_id: hipodromo.id, carrera_id: carrera.id)
    end
    ActionCable.server.broadcast 'web_notifications_banca_channel',
                                 { data: { 'tipo' => 2500,
                                           'data' => { 'id' => buscar_api_pre.id, 'hipodromo' => hipodromo.nombre,
                                                     'carrera' => carrera.numero_carrera } }}
  end

  def search_results(carrera_id, carrera_id_nyra)
    Hipodromos::Carreras.results(carrera_id, carrera_id_nyra)
  end

  def search_nyra_data(id_carrera, carrera_id_nyra)
    resultados, retirados = search_results(id_carrera, carrera_id_nyra)
    caballos = Carrera.find(id_carrera).caballos_carrera
    caballos.map do |caballo|
      llegada = resultados.find { |a| a[1] == caballo.numero_puesto }
      llegada = llegada.present? ? llegada[0].to_i : 0
      retirado = scratche?(retirados, caballo)
      { 'id' => caballo.id, 'puesto' => caballo.numero_puesto,
        'llegada' => llegada, 'retirado' => retirado }
    end
  end

  def scratche?(retirados, caballo)
    retirados.find { |a| a == caballo.numero_puesto }.present?
  end
end
