class CreateCierreCarreras < ActiveRecord::Migration[5.2]
  def change
    create_table :cierre_carreras do |t|
      t.integer :hipodromo_id
      t.integer :carrera_id
      t.integer :user_id

      t.timestamps
    end
  end
end
