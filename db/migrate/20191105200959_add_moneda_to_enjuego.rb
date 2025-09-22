class AddMonedaToEnjuego < ActiveRecord::Migration[5.2]
  def change
    add_column :enjuegos, :moneda, :integer
  end
end
