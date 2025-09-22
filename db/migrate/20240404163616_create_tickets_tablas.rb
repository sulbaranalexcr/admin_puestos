class CreateTicketsTablas < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets_tablas do |t|
      t.references :usuarios_taquilla, null: false, foreign_key: true
      t.references :tablas_detalle, null: false, foreign_key: true
      t.references :caballos_carrera, null: false, foreign_key: true
      t.references :carrera, null: false, foreign_key: true
      t.integer :cantidad_tablas
      t.float :valor
      t.float :total
      t.integer :monto_ganado, default: 0
      t.string :detalle
      t.string :gticket
      t.integer :status

      t.timestamps
    end
  end
end
