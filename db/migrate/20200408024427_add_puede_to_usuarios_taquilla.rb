class AddPuedeToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :propone, :boolean, default: true
    add_column :usuarios_taquillas, :toma, :boolean, default: true
  end
end
