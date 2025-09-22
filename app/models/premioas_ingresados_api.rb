class PremioasIngresadosApi < ApplicationRecord
  belongs_to :hipodromo
  belongs_to :carrera

   def numero_carrera 
     self.carrera.numero_carrera
   end

   def nombre_hipodromo
      self.hipodromo.nombre
   end
end
