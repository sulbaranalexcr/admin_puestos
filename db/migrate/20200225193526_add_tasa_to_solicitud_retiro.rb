class AddTasaToSolicitudRetiro < ActiveRecord::Migration[5.2]
  def change
    add_column :solicitud_retiros, :tasa, :float
    add_column :solicitud_retiros, :monto_moneda, :float
  end
end
