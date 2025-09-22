class CreateEstructuras < ActiveRecord::Migration[5.2]
  def change
    create_table :estructuras do |t|
      t.string :nombre
      t.string :representante
      t.string :rif
      t.string :telefono
      t.string :direccion
      t.string :correo
      t.integer :tipo
      t.integer :tipo_id
      t.integer :padre_id
      t.boolean :activo

      t.timestamps
    end
  end
end
