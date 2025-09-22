para = ARGV[0]
require 'json'
require_relative 'config/environment'

if para.nil?
  puts "Ejemplo de uso: ruby validar_envios_faltantes.rb 2020-12-01"
  para = Time.now
else
  para = para.to_time    
end


data_array = []
RetornosBloqueApi.where(created_at: para.all_day).each do |err|
  data_array << "Tipo: #{err.tipo}, Hipodromo: #{Carrera.find(err.carrera_id).jornada.hipodromo.nombre}, Carrera #{err.carrera_id} - #{Carrera.find(err.carrera_id).numero_carrera}" if  JSON.parse(err.data_enviada)['users'].count != JSON.parse(err.data_recibida)['users'].count
end

if data_array.count == 0
  puts "No hay errores"
else
  puts "Errores encontrados"     
  puts data_array
end