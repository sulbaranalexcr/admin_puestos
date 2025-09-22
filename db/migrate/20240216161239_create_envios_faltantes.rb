class CreateEnviosFaltantes < ActiveRecord::Migration[5.2]
  def change
    create_table :envios_faltantes do |t|
      t.string :integrador
      t.string :tipo
      t.string :destino
      t.string :data_enviada
      t.string :data_recibida

      t.timestamps
    end
  end
end
