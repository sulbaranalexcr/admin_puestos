class TablasDetalle < ApplicationRecord
  belongs_to :tablas_dinamica
  belongs_to :caballos_carrera
end
