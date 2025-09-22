class CreateCuadreGeneralCaballosPuestos < ActiveRecord::Migration[5.2]
  def change
    create_table :cuadre_general_caballos_puestos do |t|
      t.references :estructura, foreign_key: true
      t.float :venta
      t.float :premio
      t.float :comision
      t.float :utilidad
      t.integer :moneda
      t.references :carrera, foreign_key: true
      t.references :hipodromo, foreign_key: true
      t.float :monto_otro_grupo
      t.float :gano_oc
      t.float :perdio_oc
      t.float :comision_oc

      t.timestamps
    end
  end
end
