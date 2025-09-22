class CaballosCarrera < ApplicationRecord
  belongs_to :carrera
  has_many :premiacion
end
