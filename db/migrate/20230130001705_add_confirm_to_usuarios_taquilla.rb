class AddConfirmToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :need_confirm, :boolean, default: true
  end
end
