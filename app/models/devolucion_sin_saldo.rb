class DevolucionSinSaldo < ApplicationRecord
  belongs_to :usuarios_taquilla
  belongs_to :carrera
end
