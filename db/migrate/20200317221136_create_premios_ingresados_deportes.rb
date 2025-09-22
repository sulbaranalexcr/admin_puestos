class CreatePremiosIngresadosDeportes < ActiveRecord::Migration[5.2]
  def change
    create_table :premios_ingresados_deportes do |t|
      t.integer :usuario_premia
      t.integer :juego_id
      t.integer :liga_id
      t.integer :match_id
      t.text :resultado
      t.boolean :repremio

      t.timestamps
    end
  end
end
