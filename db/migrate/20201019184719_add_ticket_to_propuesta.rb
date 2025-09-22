class AddTicketToPropuesta < ActiveRecord::Migration[5.2]
  def change
    add_column :propuesta, :ticket_id, :integer, default: 0
    add_column :propuesta, :tickets_detalle_id, :integer, default: 0
  end
end
