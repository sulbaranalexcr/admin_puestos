class AddImagenToJuego < ActiveRecord::Migration[5.2]
  def change
    add_column :juegos, :imagen, :string
  end
end
