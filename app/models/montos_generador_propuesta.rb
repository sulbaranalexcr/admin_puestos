class MontosGeneradorPropuesta < ApplicationRecord
  def monto(deporte_id, tipo)
    bus_monto = data.find { |a| a['deporte_id'].to_i == deporte_id.to_i && a['tipo'].to_i == tipo.to_i }
    return bus_monto['monto'].to_f if bus_monto.present?
    0
  end
end
