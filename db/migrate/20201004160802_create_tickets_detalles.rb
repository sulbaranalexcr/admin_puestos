class CreateTicketsDetalles < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets_detalles do |t|
      t.references :ticket, foreign_key: true
      t.integer :propuesta_id, default: 0
      t.integer :enjuego_id, default: 0
      t.integer :status1, default: 0
      t.integer :status2, default: 0
      t.integer :status3, default: 0
      t.string :detalle, default: ''
      t.float :monto, default: 0
      t.float :monto_gano, default: 0


      t.timestamps
    end
  end
end
