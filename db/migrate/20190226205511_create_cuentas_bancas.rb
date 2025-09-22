class CreateCuentasBancas < ActiveRecord::Migration[5.2]
  def change
    create_table :cuentas_bancas do |t|
      t.string :banco_id
      t.string :numero_cuenta
      t.integer :tipo_cuenta
      t.string :nombre_cuenta
      t.string :cedula_cuenta
      t.string :email_cuenta
      t.integer :moneda
      t.string :detalle
      t.string :tipo
      t.string :grupo_id

      t.timestamps
    end
  end
end
