class AddIndexesToUsuariosTaquilla < ActiveRecord::Migration[7.1]
  def change
    add_index :usuarios_taquillas, :integrador_id
    add_index :usuarios_taquillas, :cliente_id
    add_index :usuarios_taquillas, :correo  
  end
end
