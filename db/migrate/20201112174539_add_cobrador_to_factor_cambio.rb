class AddCobradorToFactorCambio < ActiveRecord::Migration[5.2]
  def change
    add_column :factor_cambios, :cobrador_id, :integer, default: 0
  end
end
