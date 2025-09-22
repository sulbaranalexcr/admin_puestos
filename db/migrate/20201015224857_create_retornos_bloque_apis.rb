class CreateRetornosBloqueApis < ActiveRecord::Migration[5.2]
  def change
    create_table :retornos_bloque_apis do |t|
      t.integer :tipo
      t.integer :hipodromo_id
      t.integer :carrera_id
      t.text :data_enviada
      t.text :data_recibida
      t.boolean :procesada
      t.boolean :reintento

      t.timestamps
    end
  end
end
