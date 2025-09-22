class CreateSolicitudRetiros < ActiveRecord::Migration[5.2]
  def change
    create_table :solicitud_retiros do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.integer :tipo
      t.references :cuentas_cliente, foreign_key: true
      t.decimal :monto
      t.integer :status

      t.timestamps
    end
  end
end
