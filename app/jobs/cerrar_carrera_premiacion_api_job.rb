class CerrarCarreraPremiacionApiJob
  #< ApplicationJob
  include ApiHelper
  include Sidekiq::Worker

#  queue_as :default

  def perform(data_premio,hipodromo_id, carrera_id)
    ids_integrador = Integrador.ids
    return unless ids_integrador.present?

    datos_carrera = ''
    ids_integrador.each do |idi|
      usuarios_ids = UsuariosTaquilla.where(integrador_id: idi, usa_cajero_externo: true).pluck(:cliente_id)
      user_array = []
      datos_carrera = "#{Hipodromo.find(hipodromo_id).nombre} Carrera #{Carrera.find(carrera_id).numero_carrera}"
      data_premio.each do |prop|
        next unless usuarios_ids.include?(prop['id'])

        user_array << prop
      end
      objeto_completo = { "type": 4, "description": datos_carrera, "users": user_array }
      next unless user_array.length.positive?

      acreditar_saldos_cajero_externo(idi, objeto_completo, hipodromo_id, carrera_id, 4)
    end
  end
end
