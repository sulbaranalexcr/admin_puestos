class CreateTablasFijasDetalles < ActiveRecord::Migration[5.2]
  def change
    create_table :tablas_fijas_detalles do |t|
      t.references :tablas_fija, foreign_key: true
      t.integer :caballo_id
      t.float :costo
      t.integer :status
      t.boolean :activo

      t.timestamps
    end
  end
end
