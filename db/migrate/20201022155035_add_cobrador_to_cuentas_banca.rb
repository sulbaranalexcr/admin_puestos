class AddCobradorToCuentasBanca < ActiveRecord::Migration[5.2]
  def change
    add_column :cuentas_bancas, :cobrador_id, :integer, default: 0
  end
end
