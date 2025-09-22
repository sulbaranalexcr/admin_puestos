class CreateOperacionesCajeroIntegradors < ActiveRecord::Migration[5.2]
  def change
    create_table :operaciones_cajero_integradors do |t|
      t.integer :operacaiones_cajero_id
      t.integer :usuarios_taquilla_id
      t.integer :integrador_id
      t.decimal :monto
      t.string :detalle
      t.integer :tipo
      t.boolean :enviado, default: false
      t.boolean :procesado, default: false

      t.timestamps
    end
  end
end
