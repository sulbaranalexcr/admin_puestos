class ProxyController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def request_proxy
    render json: { status: :failed } and return unless params[:secret].present?
    render json: { status: :failed } and return unless params[:secret] = 'losvergatarios'

    response = case params[:tipo].to_i
               when 1
                 extract_racecourses
               when 2
                 extract_runners(params[:id])
               when 3
                 extract_hip(params[:id])
               end
    render json: response
  end


  def extract_racecourses
    uri = URI('https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=Jornada')
    res = Net::HTTP.get(uri)
    JSON.parse(res)['response']['data']['Jornada']
  end

  def extract_runners(race_id)
    uri = URI("https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=Corredores&Detalle=#{race_id}")
    res = Net::HTTP.get(uri)
    JSON.parse(res)['response']['data']['Corredores']
  end


  def extract_hip(racecourse)
    uri = URI("https://apuestasroyal.com/taquilla/api.php?Key=puestosAR202422&Tipo=Carreras&Detalle=#{racecourse['cardId']}")
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end

  def proxy_royal
    uri = URI(params[:url])
    render json: JSON.parse(Net::HTTP.get(uri))
  end
end 
