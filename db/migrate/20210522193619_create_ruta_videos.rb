class CreateRutaVideos < ActiveRecord::Migration[5.2]
  def change
    create_table :ruta_videos do |t|
      t.string :nombre
      t.integer :tipo
      t.string :hipodromo
      t.text :url

      t.timestamps
    end
  end
end
