class AddErroresToErroresCajeroExterno < ActiveRecord::Migration[5.2]
  def change
    add_column :errores_cajero_externos, :error, :text
  end
end
