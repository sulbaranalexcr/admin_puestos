class Moneda < ApplicationRecord
  def ultimo_cambio
    bus = HistorialTasaGrupo.where(moneda_id: self.id).last
    if bus.present?
      bus.nueva_tasa
    else
      0
    end
  end
end
