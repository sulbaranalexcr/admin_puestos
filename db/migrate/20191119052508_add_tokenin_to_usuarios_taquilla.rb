class AddTokeninToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :token_externo, :string
    add_column :usuarios_taquillas, :externo, :boolean, default: false
    add_column :usuarios_taquillas, :integrador_id, :integer
    add_column :usuarios_taquillas, :cliente_id, :string
  end
end
