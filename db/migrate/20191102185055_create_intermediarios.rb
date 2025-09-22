class CreateIntermediarios < ActiveRecord::Migration[5.2]
  def change
    create_table :intermediarios do |t|
      t.string :nombre
      t.string :representante
      t.string :direccion
      t.string :rif
      t.string :telefono
      t.string :correo
      t.boolean :activo
      t.decimal :porcentaje_banca

      t.timestamps
    end
  end
end
