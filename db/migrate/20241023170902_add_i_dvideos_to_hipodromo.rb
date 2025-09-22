class AddIDvideosToHipodromo < ActiveRecord::Migration[7.1]
  def change
    add_column :hipodromos, :id_video, :string, default: ''
  end
end
