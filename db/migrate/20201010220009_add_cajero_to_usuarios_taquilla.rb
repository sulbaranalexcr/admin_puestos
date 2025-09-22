class AddCajeroToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :usa_cajero_externo, :boolean, default: false
  end
end
