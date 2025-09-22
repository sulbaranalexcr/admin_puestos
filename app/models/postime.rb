class Postime < ApplicationRecord
  belongs_to :user

  def nombre_usuario
     User.find(self.user_id).username
  end

  def nombre_hipodromo
      Carrera.find(self.carrera_id).jornada.hipodromo.nombre_largo
  end

  def numero_carrera
      Carrera.find(self.carrera_id).numero_carrera
  end

end
