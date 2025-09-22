class CreateOperacionesCajeroApis < ActiveRecord::Migration[5.2]
  def change
    create_table :operaciones_cajero_apis do |t|
      t.references :integrador, foreign_key: true
      t.integer :transaction_id
      t.string :details
      t.float :amount

      t.timestamps
    end
  end
end
