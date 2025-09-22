class CreateDatosCajeroIntegradors < ActiveRecord::Migration[5.2]
  def change
    create_table :datos_cajero_integradors do |t|
      t.references :integrador, foreign_key: true
      t.text :datos_cajero

      t.timestamps
    end
  end
end
