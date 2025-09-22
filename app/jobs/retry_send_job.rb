class RetrySendJob
  include ApiHelper
  include Sidekiq::Worker

  def perform(integrador_id, datos, hipodromo_id, carrera_id, tipo_operacion, reintentos)
    acreditar_saldos_cajero_externo(integrador_id, datos, hipodromo_id, carrera_id, tipo_operacion, reintentos + 1)
  end
end
