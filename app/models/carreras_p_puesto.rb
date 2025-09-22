class CarrerasPPuesto < ApplicationRecord
  belongs_to :premios_ingresado
  belongs_to :carrera
  belongs_to :usuarios_taquilla
  belongs_to :operaciones_cajero
  belongs_to :propuestas_caballos_puesto
end
