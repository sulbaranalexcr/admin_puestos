class JuegosPremiado < ApplicationRecord
  belongs_to :match
  belongs_to :usuarios_taquilla
  belongs_to :propuestas_deporte
  belongs_to :operaciones_cajero
end
