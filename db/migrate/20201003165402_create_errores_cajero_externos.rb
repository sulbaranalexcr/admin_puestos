class CreateErroresCajeroExternos < ActiveRecord::Migration[5.2]
  def change
    create_table :errores_cajero_externos do |t|
      t.integer :user_id
      t.integer :transaction_id
      t.float :amount
      t.string :message

      t.timestamps
    end
  end
end
