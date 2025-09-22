require 'net/http'
require 'uri'
require 'json'
require 'fuzzystringmatch'
require_relative 'config/environment'
require 'net/smtp'
url = URI('https://api.universalrace.net/bet_api.php')

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true
request = Net::HTTP::Post.new(url)
request['Content-Type'] = 'application/x-www-form-urlencoded'
request.body = 'accion=rvideo_ba&id_b=1010'

response = https.request(request)
data = JSON.parse(response.body)
all_channels = []
data.each do |channel|
  all_channels << [channel['id_vica'], channel['vcanal']]
  break if channel['vcanal'][/video de calidad/i]
end
puts all_channels.to_json
# REDIS.set('all_channels_video', all_channels.to_json)
# REDIS.close

# api_data = JSON.parse(REDIS.get('all_channels_video'))
# REDIS.close
@jarow = FuzzyStringMatch::JaroWinkler.create(:native)
hips = []
Jornada.where(fecha: Time.now.all_day).each do |jornada|
  all_channels.each do |api|
    percent_match = (@jarow.getDistance(jornada.hipodromo.nombre, api[1].split('-')[0].strip) * 100).round(2)
    next unless percent_match >= 88

    hips << { 'id' => jornada.hipodromo_id, 'hipodromo' => jornada.hipodromo.nombre, id_video: api[0] }
  end
end
# REDIS.set('all_channels_video', hips.to_json)
# REDIS.close
InternationalVideo.create(date: Time.now, data: hips)
