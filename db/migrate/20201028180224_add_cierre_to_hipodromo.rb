class AddCierreToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :cierre_api, :boolean, default: true
    add_column :hipodromos, :cierre_api_hora, :string, default: ''
  end
end
