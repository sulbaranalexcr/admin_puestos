class CreateJuegosPremiados < ActiveRecord::Migration[5.2]
  def change
    create_table :juegos_premiados do |t|
      t.references :match, foreign_key: true
      t.references :usuarios_taquilla, foreign_key: true
      t.references :propuestas_deporte, foreign_key: true
      t.references :operaciones_cajero, foreign_key: true
      t.boolean :activo
      t.boolean :status

      t.timestamps
    end
  end
end
