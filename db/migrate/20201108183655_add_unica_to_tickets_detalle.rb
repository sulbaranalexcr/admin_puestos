class AddUnicaToTicketsDetalle < ActiveRecord::Migration[5.2]
  def change
    add_column :tickets_detalles, :propuesta_caballos_puesto_id, :integer
  end
end
