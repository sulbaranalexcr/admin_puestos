class CreateCarrerasIdsNyras < ActiveRecord::Migration[5.2]
  def change
    create_table :carreras_ids_nyras do |t|
      t.string :codigo_nyra
      t.jsonb :ids_carrera

      t.timestamps
    end
  end
end
