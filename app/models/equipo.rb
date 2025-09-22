class Equipo < ApplicationRecord

  def nombre_liga
      liga = Liga.find_by(liga_id: self.liga_id)
      if liga.present?
        liga.nombre
      else
        "Sin Liga"
      end
  end

  def nombre_deporte
    liga = Liga.find_by(liga_id: self.liga_id)
    if liga.present?
      Juego.find_by(juego_id: liga.juego_id).nombre
    else
      ""
    end

  end

end
