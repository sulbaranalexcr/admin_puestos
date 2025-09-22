class Intermediario < ApplicationRecord

  def estructura_id
    Estructura.find_by(tipo: 2, tipo_id: self.id).id
  end


end
