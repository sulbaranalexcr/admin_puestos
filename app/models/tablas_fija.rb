class TablasFija < ApplicationRecord
  belongs_to :hipodromo
  belongs_to :carrera
  has_many :tablas_fijas_detalle
end
