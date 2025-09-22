class HistorialTasaGrupo < ApplicationRecord
  belongs_to :user
  belongs_to :moneda
  belongs_to :grupo
end
