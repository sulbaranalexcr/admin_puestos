class AddTasaToSolicitudRecarga < ActiveRecord::Migration[5.2]
  def change
    add_column :solicitud_recargas, :tasa, :float
    add_column :solicitud_recargas, :monto_usd, :float
  end
end
