class CreatePorcentajesSocios < ActiveRecord::Migration[5.2]
  def change
    create_table :porcentajes_socios do |t|
      t.references :socio, foreign_key: true
      t.references :app
      t.float :porcentaje

      t.timestamps
    end
  end
end
