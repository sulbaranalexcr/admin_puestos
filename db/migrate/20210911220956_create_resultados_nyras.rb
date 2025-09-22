class CreateResultadosNyras < ActiveRecord::Migration[5.2]
  def change
    create_table :resultados_nyras do |t|
      t.references :carrera
      t.jsonb :resultados

      t.timestamps
    end
  end
end
