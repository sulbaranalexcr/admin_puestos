class CreateErroresEnviosApis < ActiveRecord::Migration[5.2]
  def change
    create_table :errores_envios_apis do |t|
      t.integer :integrador_id
      t.integer :tipo
      t.integer :hipodromo_id
      t.integer :carrera_id
      t.text :mensaje
      t.text :mensaje2
      t.boolean :leido, default: false
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
