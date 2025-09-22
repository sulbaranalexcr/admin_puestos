class OperacionesCajero < ApplicationRecord
  belongs_to :usuarios_taquilla

  # before_create :actualizar_saldos

  def actualizar_saldos
    # porcentaje_gt = self.usuarios_taquilla.comision.to_f
    # porcentaje_bg = Grupo.find(self.usuarios_taquilla.grupo_id.to_i).porcentaje_banca.to_f
    # self.porcentaje_gt = porcentaje_gt
    # self.porcentaje_bg = porcentaje_bg

    # inicio_dia = SaldosIniciodia.where(usuarios_taquilla_id: self.usuarios_taquilla_id, created_at: Time.now.all_day)
    # unless inicio_dia.present?
    #   SaldosIniciodia.create(usuarios_taquilla_id: self.usuarios_taquilla_id,monto_bs: self.usuarios_taquilla.saldo_bs.to_f,monto_usd: self.usuarios_taquilla.saldo_usd.to_f)
    # end

    # saldo_anterior = 0
    # if self.moneda == 1
    #   saldo_anterior =  self.usuarios_taquilla.saldo_bs.to_f
    #   self.usuarios_taquilla.update(saldo_bs:  saldo_anterior.to_f + self.monto.to_f)
    # else
    #   saldo_anterior =  self.usuarios_taquilla.saldo_usd.to_f
    #   self.usuarios_taquilla.update(saldo_usd:  saldo_anterior.to_f + self.monto.to_f)
    # end
    # self.saldo_anterior = saldo_anterior
    # self.saldo_actual = saldo_anterior + self.monto
    # self.monto_dolar = (self.monto / self.usuarios_taquilla.moneda_default_dolar.to_f)
  end


end
