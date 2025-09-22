class Agente < ApplicationRecord
  self.table_name = "cobradores"
  belongs_to :grupo
  has_many :factor_cambio, foreign_key: "cobrador_id"

  def moneda
    buscar = Moneda.find(self.moneda_id) if self.moneda_id.present?
    if buscar.present? 
      buscar.abreviatura
    else
      "No Asignada"
    end
  end

  def nombre_completo
    self.nombre + " " + self.apellido
  end
end
