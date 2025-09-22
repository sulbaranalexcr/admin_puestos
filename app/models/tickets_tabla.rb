class TicketsTabla < ApplicationRecord
  belongs_to :usuarios_taquilla
  belongs_to :tablas_detalle
end
