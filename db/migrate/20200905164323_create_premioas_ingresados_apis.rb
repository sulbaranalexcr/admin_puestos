class CreatePremioasIngresadosApis < ActiveRecord::Migration[5.2]
  def change
    create_table :premioas_ingresados_apis do |t|
      t.integer :hipodromo_id
      t.integer :carrera_id
      t.text :resultado
      t.integer :status, default: 1

      t.timestamps
    end
  end
end
