class AddCodigoNyraToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :codigo_nyra, :string, default: ''
  end
end
