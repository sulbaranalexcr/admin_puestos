class CreateBancos < ActiveRecord::Migration[5.2]
  def change
    create_table :bancos do |t|
      t.string :banco_id
      t.string :nombre
      t.integer :moneda

      t.timestamps
    end
  end
end
