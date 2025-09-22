class CreatePremiosIngresados < ActiveRecord::Migration[5.2]
  def change
    create_table :premios_ingresados do |t|
      t.integer :usuario_premia
      t.integer :hipodromo_id
      t.integer :jornada_id
      t.integer :carrera_id
      t.text :caballos
      t.boolean :repremio

      t.timestamps
    end
  end
end
