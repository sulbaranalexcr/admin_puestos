class AddTipoToUsuariosTaquilla < ActiveRecord::Migration[7.1]
  def change
    add_column :usuarios_taquillas, :tipo, :integer, default: 1
  end
end
