class ExchangeRate < ApplicationRecord
  def monedas
    self.data['quotes'].map do |key, value|
      moneda = Moneda.find_by(abreviatura: key[3..-1])  
      next unless moneda.present?

      { 'nombre' => moneda.nombre,
        'pais' =>  "#{moneda.pais} #{moneda.abreviatura == 'VEF' ? ' (Tiempo Real)':''}",
        'abreviatura' => moneda.abreviatura,
        'tasa' => moneda.abreviatura == 'VEF' ? extract_vef_usd(value) : value }
    end.compact.sort_by {|moneda| moneda['nombre']}
  end     

  def extract_vef_usd(value)
    require 'net/http'
    uri = URI.parse("https://s3.amazonaws.com/dolartoday/data.json")
    uri.query = URI.encode_www_form({})
    res = Net::HTTP.get_response(uri)
    JSON.parse(res.body)['USD']['dolartoday']
  rescue
    value  
  end
end
