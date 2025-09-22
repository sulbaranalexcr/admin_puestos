class CreateCuadreGeneralDeportes < ActiveRecord::Migration[5.2]
  def change
    create_table :cuadre_general_deportes do |t|
      t.references :estructura, foreign_key: true
      t.float :venta
      t.float :premio
      t.float :comision
      t.float :utilidad
      t.integer :moneda

      t.timestamps
    end
  end
end
