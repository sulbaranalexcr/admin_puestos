class AddMontoDolarToOperacionesCajero < ActiveRecord::Migration[5.2]
  def change
    add_column :operaciones_cajeros, :monto_dolar, :float, default: 0
  end
end
