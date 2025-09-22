class AddTicketToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :texto_jugada, :string, default: ''
    add_column :propuestas_deportes, :ticket_id_juega, :integer, default: 0
    add_column :propuestas_deportes, :tickets_detalle_id_juega, :integer, default: 0
    add_column :propuestas_deportes, :ticket_id_banquea, :integer, default: 0
    add_column :propuestas_deportes, :tickets_detalle_id_banquea, :integer, default: 0
  end
end
