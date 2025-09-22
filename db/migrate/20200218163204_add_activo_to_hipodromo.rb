class AddActivoToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :activo, :boolean, default: true 
  end
end
