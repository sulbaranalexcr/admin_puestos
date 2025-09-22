class CreateEnviosMasivos < ActiveRecord::Migration[7.1]
  def change
    create_table :envios_masivos do |t|
      t.references :carrera, null: false, foreign_key: true
      t.references :integrador, null: false, foreign_key: true
      t.integer :type_data
      t.jsonb :data

      t.timestamps
    end
  end
end
