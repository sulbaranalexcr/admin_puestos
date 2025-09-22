class CuentasBanca < ApplicationRecord

  def nombre_banco
      Banco.find_by(banco_id: self.banco_id).nombre
  end

  def moneda_banco
      Moneda.find(Banco.find_by(banco_id: self.banco_id).moneda).abreviatura
  end


end
