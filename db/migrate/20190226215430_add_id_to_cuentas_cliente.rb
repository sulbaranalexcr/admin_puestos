class AddIdToCuentasCliente < ActiveRecord::Migration[5.2]
  def change
    add_reference :cuentas_clientes, :usuarios_taquilla, foreign_key: true
  end
end
