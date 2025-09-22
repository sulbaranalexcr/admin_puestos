class CreateHistorialTasas < ActiveRecord::Migration[5.2]
  def change
    create_table :historial_tasas do |t|
      t.references :user, foreign_key: true
      t.integer :moneda_id
      t.float :tasa_anterior
      t.float :tasa_nueva
      t.string :ip_remota
      t.integer :grupo_id
      t.text :geo

      t.timestamps
    end
  end
end
