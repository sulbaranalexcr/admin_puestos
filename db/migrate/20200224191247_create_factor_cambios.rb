class CreateFactorCambios < ActiveRecord::Migration[5.2]
  def change
    create_table :factor_cambios do |t|
      t.integer :moneda_id
      t.integer :grupo_id
      t.float :valor_dolar, default: 1

      t.timestamps
    end
  end
end
