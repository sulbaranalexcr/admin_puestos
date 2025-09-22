# frozen_string_literal: true

require_relative 'config/environment'
include ApplicationHelper
require 'net/http'
require 'net/https'
require 'rufus-scheduler'


ENV['TZ'] = 'America/Caracas'
scheduler = Rufus::Scheduler.new

# premiacion
scheduler.cron '30 2 * * *' do
  puts 'Cerrando la aplicación...'
  exit
end

scheduler.every '30s', overlap: false  do
  uri = URI('https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=CierresResultados')
  res = Net::HTTP.get(uri)
  data = JSON.parse(res)['response']['data']['Carreras']
  results = JSON.parse(res)['response']['data']['Resultados']
  data.each do |racer|
    data_send = []
    next unless racer['raceStatus'].to_i == 5

    carrera_id = Carrera.find_by(id_api: racer['raceId'])

    next if carrera_id.nil?
    next if carrera_id.caballos_carrera.pluck(:numero_puesto).any?{ |a| a.match(/^\d[a-zA-Z]+$/) }
    next unless carrera_id.jornada.hipodromo.activo
    # next if carrera_id.jornada.hipodromo.pais.upcase == 'VENEZUELA'
    next if PremiosIngresado.find_by(carrera_id: carrera_id.id).present?
    next if carrera_id.jornada.hipodromo.cantidad_puestos.to_i > results.select { |resx| resx['raceId'] == racer['raceId'] && resx['finishPosition'].to_i.positive? }.length


    horse_with_error = false
    results.select { |resx| resx['raceId'] == racer['raceId'] }.each do |cab|
      horse = CaballosCarrera.find_by(id_api: cab['runnerId'])
      horse_with_error = true if horse.nil?
      next if cab['finishPosition'].to_i.zero?

      data_send << { 'id' => horse.id, 'puesto' => horse.numero_puesto, 'retirado' => horse.retirado, 'llegada' => cab['finishPosition'] }
    end
    next if horse_with_error

    ActionCable.server.broadcast 'web_notifications_banca_channel', data: { 'tipo' => 2500, 'data' => { 'id' => carrera_id.id, 'hipodromo' => carrera_id.hipodromo.nombre, 'carrera' => carrera_id.numero_carrera } } if data_send.find { |a| a['puesto'].match(/^\d[a-zA-Z]+$/) }.present?
    # next if data_send.find { |a| a['puesto'].match(/^\d[a-zA-Z]+$/) }.present?

    send_data(carrera_id.id, data_send, racer['raceId']) if data_send.length.positive?
  end
rescue StandardError => e
end

def send_sistemas(url, carrera_id, id_api, caballos)
  Thread.new {
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
    req.body = { 'id' => carrera_id, 'id_api' => id_api, 'caballos' => caballos, 'premia_api' => true, 'recibe_puestos' => true }.to_json
    https.request(req)
  }
end

def send_data(carrera_id, caballos, id_api)
  Thread.new {
    uri = URI.parse('https://admin.betsolutionsgroup.com/unica/premiacion_puestos/premiar_puestos')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
    req.body = { 'id' => carrera_id, 'caballos' => caballos, 'premia_api' => true }.to_json
    https.request(req)
  }

  sistemas = ["https://admin.unpuestos.com/unica/premiacion_puestos/premiar_puestos",
              "https://admin.tablasdinamica.com/unica/premiacion_tablas/premiar_tablas",
              "https://admin.rojosynegros.com/unica/premiacion_rojonegro/premiar_rojonegro",
              "https://admin.piramidehipica.com/unica/premiacion_piramide/premiar_piramide"]
  sistemas.each do |sis_url|
    Thread.new { 
      send_sistemas(sis_url, carrera_id, id_api, data_send)
    }
  end
end





# scheduler.every '30s' do
#   redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#   redis.set('premiacion_api', Time.now.to_s)
# end

scheduler.join
