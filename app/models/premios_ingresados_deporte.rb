class PremiosIngresadosDeporte < ApplicationRecord


  def nombre_usuario
    User.find(self.usuario_premia).username
  end

  def nombre_deporte
    Juego.find_by(juego_id: self.juego_id).nombre
  end

  def liga 
    Liga.find_by(liga_id: self.liga_id).nombre
  end

  def nombre_match 
    Match.find_by(match_id: self.match_id).nombre
  end

end
