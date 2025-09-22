class CreatePremiacionDeportes < ActiveRecord::Migration[5.2]
  def change
    create_table :premiacion_deportes do |t|
      t.integer :juego_id
      t.integer :liga_id
      t.integer :match_id
      t.integer :tipo_apuesta
      t.integer :id_quien_juega
      t.integer :id_quien_banquea
      t.decimal :monto_quien_juega
      t.decimal :monto_quien_banquea
      t.integer :usuario_premia_id
      t.integer :id_equipo_gana
      t.boolean :repremiado
      t.decimal :monto_pagado
      t.decimal :monto_pagado_completo
      t.integer :moneda
      t.integer :id_gana
      t.decimal :porcentaje_gt
      t.decimal :porcentaje_bg

      t.timestamps
    end
  end
end
