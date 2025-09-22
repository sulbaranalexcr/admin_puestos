class AddMontosToPropuestasCaballosPuesto < ActiveRecord::Migration[7.1]
  def change
    add_column :propuestas_caballos_puestos, :monto_original_juega, :float, default: 0
    add_column :propuestas_caballos_puestos, :monto_original_banquea, :float, default: 0
  end
end
