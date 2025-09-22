class CreatePagosSocios < ActiveRecord::Migration[5.2]
  def change
    create_table :pagos_socios do |t|
      t.references :socio, foreign_key: true
      t.references :app, foreign_key: true
      t.string :referencia
      t.float :monto_participacion
      t.float :monto_pagado
      t.float :saldo
      t.integer :moneda

      t.timestamps
    end
  end
end
