class CreateMatches < ActiveRecord::Migration[5.2]
  def change

    create_table :matches do |t|
      t.integer :match_id
      t.string :nombre
      t.string :utc
      t.datetime :local
      t.text :match
      t.integer :juego_id
      t.integer :liga_id

      t.timestamps
    end
  end
  
end
