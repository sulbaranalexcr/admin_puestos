class AddCheckToUsuariosGenerador < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_generadors, :can_send, :boolean, default: true
  end
end
