class Premiacion < ApplicationRecord
  belongs_to :carrera
  belongs_to :caballos_carrera

  before_create :actualizar_datos


  def actualizar_datos
    if self.id_gana.to_i > 0
        user_taq = UsuariosTaquilla.find(self.id_gana)
        porcentaje_gt = user_taq.comision.to_f
        porcentaje_bg = Grupo.find(user_taq.grupo_id.to_i).porcentaje_banca.to_f
        self.porcentaje_gt = porcentaje_gt
        self.porcentaje_bg = porcentaje_bg
    end
  end

  def grupo
      Grupo.find(UsuariosTaquilla.find(self.id_quien_banquea).grupo_id)
  end



# , porcentaje_gt: porcentaje_gt, porcentaje_bg: porcentaje_bg
#
end
