class CreateMonedasGrupos < ActiveRecord::Migration[5.2]
  def change
    create_table :monedas_grupos do |t|
      t.references :grupo, foreign_key: true
      t.integer :moneda_id
      t.float :tasa_unidad
      t.boolean :activa, default: true

      t.timestamps
    end
  end
end
