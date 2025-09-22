class CreatePremiacions < ActiveRecord::Migration[5.2]
  def change
    create_table :premiacions do |t|
      t.references :carrera, foreign_key: true
      t.references :caballos_carrera, foreign_key: true
      t.integer :tipo_apuesta
      t.integer :id_quien_juega
      t.integer :id_quien_banquea
      t.decimal :monto_quien_juega
      t.decimal :monto_quien_banquea
      t.integer :usuario_premia_id
      t.integer :llegada_caballo
      t.boolean :repremiado, defult: false
      t.decimal :monto_pagado

      t.timestamps
    end
  end
end
