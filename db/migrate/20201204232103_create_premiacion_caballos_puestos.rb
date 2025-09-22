class CreatePremiacionCaballosPuestos < ActiveRecord::Migration[5.2]
  def change
    create_table :premiacion_caballos_puestos do |t|
      t.integer :moneda
      t.references :carrera, foreign_key: true
      t.integer :id_quien_juega
      t.integer :id_quien_banquea
      t.integer :id_gana
      t.float :monto_pagado_completo

      t.timestamps
    end
  end
end
