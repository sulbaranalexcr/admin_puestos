class CreateDevolucionSinSaldoDeportes < ActiveRecord::Migration[5.2]
  def change
    create_table :devolucion_sin_saldo_deportes do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.integer :juego_id
      t.integer :match_id
      t.float :monto
      t.string :nombre_match

      t.timestamps
    end
  end
end
