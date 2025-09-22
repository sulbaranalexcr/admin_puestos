class CreateTablasFijas < ActiveRecord::Migration[5.2]
  def change
    create_table :tablas_fijas do |t|
      t.references :hipodromo, foreign_key: true
      t.references :carrera, foreign_key: true
      t.float :premio
      t.integer :disponible
      t.float :comision
      t.boolean :activo

      t.timestamps
    end
  end
end
