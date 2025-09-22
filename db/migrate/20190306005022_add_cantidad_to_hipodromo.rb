class AddCantidadToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :cantidad_puestos, :integer
  end
end
