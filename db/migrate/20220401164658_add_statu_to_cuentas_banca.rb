class AddStatuToCuentasBanca < ActiveRecord::Migration[5.2]
  def change
    add_column :cuentas_bancas, :activa, :boolean, default: true
  end
end
