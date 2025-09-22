class AddMontooriginalToTicketsDetalle < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets_detalles, :monto_original, :float
  end
end
