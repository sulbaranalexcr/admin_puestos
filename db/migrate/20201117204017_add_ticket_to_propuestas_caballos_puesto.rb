class AddTicketToPropuestasCaballosPuesto < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_caballos_puestos, :ticket_id_juega, :integer, default: 0
    add_column :propuestas_caballos_puestos, :tickets_detalle_id_juega, :integer, default: 0
    add_column :propuestas_caballos_puestos, :ticket_id_banquea, :integer, default: 0
    add_column :propuestas_caballos_puestos, :tickets_detalle_id_banquea, :integer, default: 0
  end
end
