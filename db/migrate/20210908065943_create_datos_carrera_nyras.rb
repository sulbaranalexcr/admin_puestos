class CreateDatosCarreraNyras < ActiveRecord::Migration[5.2]
  def change
    create_table :datos_carrera_nyras do |t|
      t.string :codigo
      t.integer :numero_carrera
      t.integer :carrera_id_nyra
      t.jsonb :retirados
      t.integer :status

      t.timestamps
    end
  end
end
