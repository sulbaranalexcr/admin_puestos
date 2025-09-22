class AddIdGrupoToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :grupo_id, :integer
    add_column :users, :activo, :boolean
  end
end
