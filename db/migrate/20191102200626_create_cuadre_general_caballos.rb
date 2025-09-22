class CreateCuadreGeneralCaballos < ActiveRecord::Migration[5.2]
  def change
    create_table :cuadre_general_caballos do |t|
      t.references :estructura, foreign_key: true
      t.decimal :venta
      t.decimal :premio
      t.decimal :comision
      t.decimal :utilidad
      t.integer :moneda

      t.timestamps
    end
  end
end
