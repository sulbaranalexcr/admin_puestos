class CreateTablasDinamicas < ActiveRecord::Migration[7.1]
  def change
    create_table :tablas_dinamicas do |t|
      t.references :hipodromo, null: false, foreign_key: true
      t.references :jornada, null: false, foreign_key: true
      t.references :carrera, null: false, foreign_key: true
      t.float :monto_pagar
      t.integer :status

      t.timestamps
    end
  end
end
