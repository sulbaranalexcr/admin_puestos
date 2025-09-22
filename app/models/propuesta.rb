class Propuesta < ApplicationRecord
  belongs_to :usuarios_taquilla
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  attr_accessor :nombre_hipodromo,:carrera,:nombre_caballo,:nombre_jugador,:hora_carrera,:tipo_apuesta

     def tipo_apuesta
       TipoApuesta.find(self.tipo_id).nombre
     end

     def nombre_hipodromo
       Hipodromo.find(self.hipodromo_id).nombre
     end

     def nombre_hipodromo_largo
       Hipodromo.find(self.hipodromo_id).nombre_largo
     end

     def carrera
       Carrera.find(self.carrera_id)
     end

     def nombre_carrera
       Carrera.find(self.carrera_id).numero_carrera
     end

     def hora_carrera
       Carrera.find(self.carrera_id).hora_carrera
     end

     def nombre_caballo
       CaballosCarrera.find(self.caballo_id).nombre
     end

     def nombre_caballo
       CaballosCarrera.find(self.caballo_id).nombre
     end

     def nombre_jugador
       UsuariosTaquilla.find(self.usuarios_taquilla_id).alias
     end


     def jugada_completa_banquear
        mont1 = ""
       if self.tipo_id > 18
          if self.moneda == 1
            mont1 =  number_to_currency((self.monto.to_f / TipoApuesta.find(self.tipo_id).forma_pagar.to_f).round(2), unit: "BsS. ", separator: ".", delimiter: ",")
            mont1 += " para "
            mont1 += number_to_currency(self.monto.round(2), unit: "", separator: ".", delimiter: ",")
          else
            mont1 = number_to_currency((self.monto.to_f / TipoApuesta.find(self.tipo_id).forma_pagar.to_f).round(2), unit: "UND: ", separator: ".", delimiter: ",")
            mont1 += " para "
            mont1 += number_to_currency(self.monto.round(2), unit: "", separator: ".", delimiter: ",")
          end
       else
          if self.moneda == 1
             mont1 += number_to_currency(self.monto.round(2), unit: "BsS.", separator: ".", delimiter: ",")
           else
             mont1 += number_to_currency(self.monto.round(2), unit: "UND: ", separator: ".", delimiter: ",")
           end
       end
         "Banqueo " + Hipodromo.find(self.hipodromo_id).nombre.upcase + "/ C#" +  Carrera.find(self.carrera_id).numero_carrera + "/" + CaballosCarrera.find(self.caballo_id).nombre + "/" + TipoApuesta.find(self.tipo_id).nombre + "/ "+  mont1
     end


     def jugada_completa_jugar
        mont1 = ""
       if self.tipo_id > 18
          if self.moneda == 1
            mont1 = number_to_currency(self.monto.round(2), unit: "", separator: ".", delimiter: ",")
            mont1 += " para "
            mont1 +=  number_to_currency((self.monto.to_f * TipoApuesta.find(self.tipo_id).forma_pagar.to_f).round(2), unit: "BsS. ", separator: ".", delimiter: ",")
          else
            mont1 = number_to_currency(self.monto.round(2), unit: "", separator: ".", delimiter: ",")
            mont1 += " para "
            mont1 += number_to_currency((self.monto.to_f * TipoApuesta.find(self.tipo_id).forma_pagar.to_f).round(2), unit: "UND: ", separator: ".", delimiter: ",")
          end
       else
          if self.moneda == 1
             mont1 += number_to_currency(self.monto.round(2), unit: "BsS.", separator: ".", delimiter: ",")
           else
             mont1 += number_to_currency(self.monto.round(2), unit: "UND: ", separator: ".", delimiter: ",")
           end
       end
         "Jugo " + Hipodromo.find(self.hipodromo_id).nombre.upcase + "/ C#" +  Carrera.find(self.carrera_id).numero_carrera + "/" + CaballosCarrera.find(self.caballo_id).nombre + "/" + TipoApuesta.find(self.tipo_id).nombre + "/ "+  mont1
     end


    def jugada_completa_banquear_api
         "Banqueo " + Hipodromo.find(self.hipodromo_id).nombre.upcase + "/ C#" +  Carrera.find(self.carrera_id).numero_carrera + "/" + CaballosCarrera.find(self.caballo_id).nombre + "/" + TipoApuesta.find(self.tipo_id).nombre 
    end

    def jugada_completa_jugar_api
        mont1 = ""
         "Jugo " + Hipodromo.find(self.hipodromo_id).nombre.upcase + "/ Carrera" +  Carrera.find(self.carrera_id).numero_carrera + "/" + CaballosCarrera.find(self.caballo_id).nombre + "/" + TipoApuesta.find(self.tipo_id).nombre
    end

    def status_propuesta()
      text_status2(self.status2)
    end

    def hijas
      prop = Propuesta.where(corte_id: self.id).where.not(status2: 4).order(:id)
      if prop.present?
        prop.map {|e| [e.monto, e.status_propuesta]}
      else
        false
      end
    end

end
