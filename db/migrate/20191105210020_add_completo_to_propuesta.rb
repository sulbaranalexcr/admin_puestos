class AddCompletoToPropuesta < ActiveRecord::Migration[5.2]
  def change
    add_column :propuesta, :monto_gana_completo, :float
    add_column :propuesta, :monto_enjuego, :float
  end
end
