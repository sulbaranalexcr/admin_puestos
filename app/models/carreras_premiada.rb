class CarrerasPremiada < ApplicationRecord
  belongs_to :premios_ingresado
  belongs_to :carrera
  belongs_to :operaciones_cajero
  belongs_to :usuarios_taquilla
  belongs_to :enjuego
end
