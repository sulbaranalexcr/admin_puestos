class CreateBancosClientes < ActiveRecord::Migration[5.2]
  def change
    create_table :bancos_clientes do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.string :banco_id
      t.string :nombre
      t.integer :tipo_cuenta
      t.string :nombre_cliente
      t.string :cedula_cliente
      t.string :telefono
      t.string :email

      t.timestamps
    end
  end
end
