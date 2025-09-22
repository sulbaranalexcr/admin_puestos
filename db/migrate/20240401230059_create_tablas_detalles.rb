class CreateTablasDetalles < ActiveRecord::Migration[7.1]
  def change
    create_table :tablas_detalles do |t|
      t.references :tablas_dinamica, null: false, foreign_key: true
      t.references :caballos_carrera, null: false, foreign_key: true
      t.boolean :retirado, default: false
      t.float :valor
      t.integer :cantidad_tablas
      t.integer :cantidad_vendida, default: 0
      
      t.timestamps
    end
  end
end
