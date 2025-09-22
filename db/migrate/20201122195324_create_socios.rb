class CreateSocios < ActiveRecord::Migration[5.2]
  def change
    create_table :socios do |t|
      t.string :nombre
      t.string :apellido
      t.integer :nivel
      t.boolean :activo
      t.datetime :ultimo_pago

      t.timestamps
    end
  end
end
