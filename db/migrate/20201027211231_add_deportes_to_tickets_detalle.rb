class AddDeportesToTicketsDetalle < ActiveRecord::Migration[5.2]
  def change
    add_column :tickets_detalles, :propuesta_deporte_id, :integer, default: 0
    add_column :tickets_detalles, :propuesta_caballo_id, :integer, default: 0
    add_column :tickets_detalles, :id_propone, :integer, default: 0
    add_column :tickets_detalles, :id_toma, :integer, default: 0
  end
end
