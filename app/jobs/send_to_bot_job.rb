class SendToBotJob
  include Sidekiq::Worker

  def perform(data)
    require 'net/http'
    require 'uri'
    parametros = { "msg": data.to_json }
    response = Net::HTTP.post URI('https://bot2.horser.site:8443/bot/sendMessage'), parametros.to_json, "Content-Type" => "application/json"
    response.body
    EnviosFaltante.create(integrador: 'Apuestas Royal', tipo: 'endpoint', destino: 'https://bot2.horser.site:8443/bot/sendMessage', 
                          data_enviada: data.to_json, data_recibida: response.body)
  end
end
