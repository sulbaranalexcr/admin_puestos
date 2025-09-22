class AddCobradorToHistorialTasa < ActiveRecord::Migration[5.2]
  def change
    add_column :historial_tasas, :cobrador_id, :integer
  end
end
