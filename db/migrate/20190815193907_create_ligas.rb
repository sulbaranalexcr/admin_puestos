class CreateLigas < ActiveRecord::Migration[5.2]

  def change
    create_table :ligas do |t|
      t.integer :juego_id
      t.integer :liga_id
      t.string :nombre

      t.timestamps
    end
  end

end
