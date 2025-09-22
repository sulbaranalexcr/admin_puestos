class CreateEnviosTaquillas < ActiveRecord::Migration[5.2]
  def change
    create_table :envios_taquillas do |t|
      t.string :tipo
      t.references :usuarios_taquilla, foreign_key: true
      t.references :tickets_detalle, foreign_key: true
      t.text :enviado
      t.text :recibido

      t.timestamps
    end
  end
end
