class CreateEquipos < ActiveRecord::Migration[5.2]

  def change
    create_table :equipos do |t|
      t.integer :equipo_id
      t.string :nombre
      t.string :nombre_largo
      t.integer :liga_id

      t.timestamps
    end
  end

end
