# frozen_string_literal: true

require_relative 'config/environment'
include ApplicationHelper
require 'net/http'
require 'net/https'
require 'rufus-scheduler'

ENV['TZ'] = 'America/Caracas'
scheduler = Rufus::Scheduler.new


# premiacion
def premiarx
  horse = CaballosCarrera.last(4).to_a
  carr_id = CaballosCarrera.last.carrera.id
  data_send = []
  4.times do |tim|
    data_send << { 'id' => horse[tim].id, 'puesto' => horse[tim].numero_puesto, 'retirado' => horse[tim].retirado, 'llegada' => tim + 1 }
  end
  send_data(carr_id, data_send)
end

def send_data(carrera_id, caballos)
  uri = URI.parse('http://localhost:4000/unica/premiacion_puestos/premiar_puestos')
  https = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => carrera_id, 'caballos' => caballos, 'premia_api' => true }.to_json
  https.request(req)
end

# scheduler.every '30s' do
#   redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#   redis.set('premiacion_api', Time.now.to_s)
# end

premiarx