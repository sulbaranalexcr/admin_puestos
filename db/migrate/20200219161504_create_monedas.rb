class CreateMonedas < ActiveRecord::Migration[5.2]
  def change
    create_table :monedas do |t|
      t.string :pais
      t.string :nombre
      t.string :abreviatura
      t.boolean :activa, default: true

      t.timestamps
    end
  end
end
