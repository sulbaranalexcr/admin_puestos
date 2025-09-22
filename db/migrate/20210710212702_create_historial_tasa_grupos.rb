class CreateHistorialTasaGrupos < ActiveRecord::Migration[5.2]
  def change
    create_table :historial_tasa_grupos do |t|
      t.references :grupo
      t.references :moneda
      t.references :user
      t.float :tasa_anterior
      t.float :nueva_tasa

      t.timestamps
    end
  end
end
