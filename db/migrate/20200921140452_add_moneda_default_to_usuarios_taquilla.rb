class AddMonedaDefaultToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :simbolo_moneda_default, :string, default: "Bs."
    add_column :usuarios_taquillas, :moneda_default_dolar, :float, default: 0
  end
end
