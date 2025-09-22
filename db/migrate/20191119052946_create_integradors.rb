class CreateIntegradors < ActiveRecord::Migration[5.2]
  def change
    create_table :integradors do |t|
      t.string :nombre
      t.string :representante
      t.string :telefono
      t.string :api_key
      t.integer :grupo_id
      t.string :ip_integrador
      t.boolean :activo

      t.timestamps
    end
  end
end
