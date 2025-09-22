class CreateCarrerasPremiadas < ActiveRecord::Migration[5.2]
  def change
    create_table :carreras_premiadas do |t|
      t.references :premios_ingresado, foreign_key: true
      t.references :carrera, foreign_key: true
      t.references :usuarios_taquilla, foreign_key: true
      t.references :operaciones_cajero, foreign_key: true
      t.references :enjuego, foreign_key: true
      t.boolean :activo
      t.integer :status
      t.timestamps
    end
  end
end
