class CreateMovimientoCajeros < ActiveRecord::Migration[7.1]
  def change
    create_table :movimiento_cajeros do |t|
      t.references :usuarios_taquilla, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.float :monto
      t.integer :type_operation
      t.string :detalle

      t.timestamps
    end
  end
end
