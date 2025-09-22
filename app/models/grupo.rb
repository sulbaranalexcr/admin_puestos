class Grupo < ApplicationRecord
  has_many :usuarios_taquilla
  belongs_to :intermediario, optional: true

  def estructura_id
    Estructura.find_by(tipo: 3, tipo_id: self.id).id
  end
end
