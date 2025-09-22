class CreatePostimes < ActiveRecord::Migration[5.2]
  def change
    create_table :postimes do |t|
      t.references :user, foreign_key: true
      t.string :hora_anterior
      t.string :nueva_hora
      t.integer :carrera_id

      t.timestamps
    end
  end
end
