class CreateSolicitudRecargas < ActiveRecord::Migration[5.2]
  def change
    create_table :solicitud_recargas do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.integer :tipo
      t.references :cuentas_banca, foreign_key: true
      t.datetime :fecha_deposito
      t.decimal :monto
      t.string :numero_operacion
      t.text :foto
      t.integer :status

      t.timestamps
    end
  end
end
