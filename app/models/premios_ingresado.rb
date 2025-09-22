class PremiosIngresado < ApplicationRecord


  def nombre_usuario
    User.find(self.usuario_premia).username
  end

  def nombre_hipodromo
    Hipodromo.find(self.hipodromo_id).nombre_largo
  end

  def carrera 
    Carrera.find(self.carrera_id).numero_carrera
  end

end
