class FactorCambio < ApplicationRecord
  belongs_to :agentes, class_name: 'Cobradore', foreign_key: "cobrador_id"

  def moneda
    mon = Moneda.find(self.moneda_id)
    [mon.abreviatura,mon.pais]
  end

end
