class Liga < ApplicationRecord
belongs_to :juego, :primary_key => "juego_id"

def nombre_deporte
  jue = Juego.find_by(juego_id: self.juego_id)
  if jue.present?
    jue.nombre
  else
    ""
  end
end

end
