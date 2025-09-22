class AddActivoToLiga < ActiveRecord::Migration[5.2]
  def change
    add_column :ligas, :activo, :boolean
    add_column :ligas, :status, :integer
  end
end
