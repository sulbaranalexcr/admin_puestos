class PagosSocio < ApplicationRecord
  belongs_to :socio
  belongs_to :app
end
