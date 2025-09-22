class CreateReglas < ActiveRecord::Migration[5.2]
  def change
    create_table :reglas do |t|
      t.text :texto
      t.boolean :activo

      t.timestamps
    end
  end
end
