class AddNombrelargoToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :nombre_largo, :string
  end
end
