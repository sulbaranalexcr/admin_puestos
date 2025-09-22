class AddTicketToEnjuego < ActiveRecord::Migration[5.2]
  def change
    add_column :enjuegos, :ticket_id, :integer, default: 0
    add_column :enjuegos, :tickets_detalle_id, :integer, default: 0
  end
end
