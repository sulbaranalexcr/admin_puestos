class CreateDevolucionSinSaldos < ActiveRecord::Migration[5.2]
  def change
    create_table :devolucion_sin_saldos do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.references :carrera, foreign_key: true
      t.decimal :monto
      t.integer :moneda

      t.timestamps
    end
  end
end
