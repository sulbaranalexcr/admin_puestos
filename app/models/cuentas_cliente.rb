class CuentasCliente < ApplicationRecord
  belongs_to :usuarios_taquilla


  def nombre_banco
      Banco.find_by(banco_id: self.banco_id).nombre
  end

end
