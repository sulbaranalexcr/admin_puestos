class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.references :usuarios_taquilla, foreign_key: true
      t.integer :tipo_juego, default: 1
      t.integer :status1, default: 0
      t.integer :status2, default: 0
      t.integer :status3, default: 0
      t.float :monto, default: 0
      t.float :monto_gano, default: 0

      t.timestamps
    end
  end
end
