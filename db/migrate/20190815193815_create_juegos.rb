class CreateJuegos < ActiveRecord::Migration[5.2]

  def change
    create_table :juegos do |t|
      t.integer :juego_id
      t.string :nombre

      t.timestamps
    end
  end

end
