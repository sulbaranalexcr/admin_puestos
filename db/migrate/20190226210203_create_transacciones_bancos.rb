class CreateTransaccionesBancos < ActiveRecord::Migration[5.2]
  def change
    create_table :transacciones_bancos do |t|
      t.string :banco_id
      t.integer :tipo_operacion
      t.integer :forma_pago
      t.decimal :monto
      t.integer :status
      t.string :referencia
      t.integer :cuenta_id

      t.timestamps
    end
  end
end
