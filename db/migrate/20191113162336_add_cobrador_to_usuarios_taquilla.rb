class AddCobradorToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :cobrador_id, :integer, default: 0
  end
end
