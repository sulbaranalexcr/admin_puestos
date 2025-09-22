class AddCorteoToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :corte_id, :integer, default: 0
  end
end
