class TablasDinamica < ApplicationRecord
  belongs_to :hipodromo
  belongs_to :jornada
  belongs_to :carrera
  has_many :tablas_detalles

  enum status: %w[inactiva activa suspendida procesada]
end
