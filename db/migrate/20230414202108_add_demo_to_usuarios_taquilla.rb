class AddDemoToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :demo, :boolean, default: false
  end
end
