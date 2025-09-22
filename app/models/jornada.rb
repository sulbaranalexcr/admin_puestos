class Jornada < ApplicationRecord
  belongs_to :hipodromo
  has_many :carrera, dependent: :destroy
  attr_accessor :fecha_bonita

  def fecha_bonita
     return self.fecha.strftime("%d/%m/%Y")
  end
end
