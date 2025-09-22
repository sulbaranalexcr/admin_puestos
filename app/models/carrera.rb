class Carrera < ApplicationRecord
  belongs_to :jornada
  has_many :caballos_carrera, dependent: :destroy
  has_many :premiacion
  has_many :premioas_ingresados_api
  has_one :cierre_carrera
  attr_accessor :premiada,:ingresada

  def premiada?
    PremiosIngresado.where(carrera_id: id).count.positive?
  end
end
