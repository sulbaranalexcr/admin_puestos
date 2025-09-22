class AddGticketToTicketsDetalle < ActiveRecord::Migration[5.2]
  def change
    add_column :tickets_detalles, :gticket, :string, default: ''
  end
end
