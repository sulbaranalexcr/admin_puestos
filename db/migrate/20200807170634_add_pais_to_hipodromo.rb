class AddPaisToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :pais, :string
    add_column :hipodromos, :bandera, :string
  end
end
