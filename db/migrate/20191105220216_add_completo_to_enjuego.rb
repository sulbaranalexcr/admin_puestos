class AddCompletoToEnjuego < ActiveRecord::Migration[5.2]
  def change
    add_column :enjuegos, :monto_ganar_completo, :float
  end
end
