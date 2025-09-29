# frozen_string_literal: true

require_relative 'config/environment'
include ApplicationHelper
require 'net/http'
require 'rufus-scheduler'
require './retirados.rb'

ENV['TZ'] = 'America/Caracas'
scheduler = Rufus::Scheduler.new

scheduler.cron '00 01 * * *' do
  REDIS.del('cierre_carre')
  REDIS.close
end

scheduler.cron '30 2 * * *' do
  puts 'Cerrando la aplicación...'
  exit
end

scheduler.cron '00 06 * * *' do
  uri = URI('https://smcvenezuela.xyz/dolarsmcbot/binance-api.php')
  res = JSON.parse(Net::HTTP.get(uri))
  ActiveRecord::Base.transaction do
    ves2 = res['VES'].to_f.ceil
    ves = ((res['VES'].to_f / 50).ceil) * 50
    clp = res['CLP'].to_f.ceil

    UsuariosTaquilla.where(simbolo_moneda_default: 'CLP').update_all(moneda_default_dolar: clp, jugada_minima_usd: clp) if clp.to_f.positive?

    UsuariosTaquilla.where(simbolo_moneda_default: ['VES', 'VEF'])
                    .update_all(jugada_minima_usd: ves) if ves.to_f.positive?
    update_tasa(1, ves2)
    update_tasa(40, clp)
  end
end

def update_tasa(moneda, monto)
  return if monto <= 0

  ant = HistorialTasa.where(moneda_id: moneda).last
  tasa_ant = ant.present? ? ant.tasa_nueva : 0
  FactorCambio.where(moneda_id: moneda).update_all(valor_dolar: monto) if moneda == 40
  HistorialTasa.create(user_id: User.first.id, moneda_id: moneda, tasa_anterior: tasa_ant, tasa_nueva: monto, ip_remota: '', grupo_id: 0, geo: '')
  Grupo.all.each do |grp|
    his = HistorialTasaGrupo.where(grupo_id: grp.id, moneda_id: moneda)
    tasa_ant = his.present? ? his.last.nueva_tasa.to_f : 0
    if his.present?
      HistorialTasaGrupo.create(user_id: User.first.id, grupo_id: grp.id, moneda_id: moneda, tasa_anterior: tasa_ant, nueva_tasa: monto)
    else
      HistorialTasaGrupo.create(user_id: User.first.id, grupo_id: grp.id, moneda_id: moneda, tasa_anterior: 0, nueva_tasa: monto)
    end
  end
end

scheduler.cron '00 08 * * *' do
  Hipodromos::Carreras.cargar_hipodromo()
end


scheduler.cron '00 11 * * *' do
  redis = Redis.new
  Hipodromos::Carreras.cargar_hipodromo() unless redis.exists?('carreras_nyra')
end




# cierre carreras automatico local sin api
def send_to_api(carrera_id, id_api, hipodrmo_id, numero_carrera)
  uri = URI.parse('https://admin-puesto.aposta2.com/api/cierre_carrera_interno')
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
  req.body = { 'id' => carrera_id, 'id_api' => id_api, 'hipodromo_id' => hipodrmo_id, 'numero_carrera' => numero_carrera }.to_json
  https.request(req)
rescue StandardError => e
  puts e
end

scheduler.every '30s', overlap: false  do
  #### carreras
  carreras_ant = Carrera.where(activo: true, jornada_id: Jornada.where(fecha: Time.now.all_day, hipodromo_id: Hipodromo.where(cierre_api: false).ids).ids)
                        .where("substr(carreras.hora_carrera,1,5)  <= '#{(Time.now + 20.seconds).strftime('%H:%M:%S')}' and hora_carrera != ''")
                        .order(:hora_carrera)
  carreras_ant.each do |carrera|
    send_to_api(carrera.id, carrera.id_api, carrera.jornada.hipodromo.abreviatura, carrera.numero_carrera)
  end
end

scheduler.join
