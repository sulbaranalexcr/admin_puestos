class AddDetalleToPropuestasCaballo < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_caballos, :texto_jugada, :string, default: ''
    add_column :propuestas_caballos, :ticket_id_juega, :integer, default: 0
    add_column :propuestas_caballos, :tickets_detalle_id_juega, :integer, default: 0
    add_column :propuestas_caballos, :ticket_id_banquea, :integer, default: 0
    add_column :propuestas_caballos, :tickets_detalle_id_banquea, :integer, default: 0
  end
end
