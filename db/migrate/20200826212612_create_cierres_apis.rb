class CreateCierresApis < ActiveRecord::Migration[5.2]
  def change
    create_table :cierres_apis do |t|
      t.boolean :es_api
      t.integer :hipodromo_id
      t.integer :carrera_id

      t.timestamps
    end
  end
end
