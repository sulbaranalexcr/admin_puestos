class ProxyInmejorableController < ApplicationController
  skip_before_action :verify_authenticity_token
 
  def proxy_caballos
    uri = URI("https://puestos.elinmejorable.dev/v1/tracks/races?raceDate=#{Time.now.strftime('%Y-%m-%d')}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true 
    request = Net::HTTP::Get.new(uri)
    request['X-API-Key'] = '04402771-13ab-4c1a-8397-d32f85b377b4'
    request['Accept'] = 'application/json'
    response = http.request(request)
    
    render json: JSON.parse(response.body)
  end
end 
