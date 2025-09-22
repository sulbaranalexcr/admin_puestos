class HistorialTasa < ApplicationRecord
  belongs_to :user
  belongs_to :moneda


  def nombre_agente
    bus = Cobradore.find_by(id: self.cobrador_id)
    if bus.present? 
      bus.nombre 
    else
      ""
    end
  end

end

