class AddAbreviaturaToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :abreviatura, :string
  end
end
