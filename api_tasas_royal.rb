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

scheduler.cron '00 07 * * *' do
  uri = URI('https://smcvenezuela.xyz/dolarsmcbot/binance-api.php')
  res = JSON.parse(Net::HTTP.get(uri))
  ActiveRecord::Base.transaction do
    clp = res['CLP'].to_f.round(2)
    ves = res['VES'].to_f.round(2)
    UsuariosTaquilla.where(simbolo_moneda_default: 'CLP')
                    .update_all(moneda_default_dolar: clp, jugada_minima_usd: clp) if clp.to_f.positive?
    UsuariosTaquilla.where(simbolo_moneda_default: ['VES', 'VEF'])
                    .update_all(moneda_default_dolar: ves, jugada_minima_usd: ves) if ves.to_f.positive?
    update_tasa(40, clp)
    update_tasa(1, ves)
  end
end

def update_tasa(moneda, monto)
  return if monto <= 0

  ant = HistorialTasa.where(moneda_id: moneda).last
  tasa_ant = ant.present? ? ant.tasa_nueva : 0
  FactorCambio.where(moneda_id: moneda).update_all(valor_dolar: monto)
  HistorialTasa.create(user_id: User.first.id, moneda_id: moneda, tasa_anterior: tasa_ant, tasa_nueva: monto, ip_remota: '', grupo_id: 0, geo: '')
  Grupo.all.each do |grp|
    his = HistorialTasaGrupo.where(grupo_id: grp.id, moneda_id: moneda)
    tasa_ant = his.present? ? his.last.nueva_tasa.to_f : 0
    HistorialTasaGrupo.create(user_id: User.first.id, grupo_id: grp.id, moneda_id: moneda, tasa_anterior: tasa_ant, nueva_tasa: monto) if his.present?
  end
end




scheduler.join
