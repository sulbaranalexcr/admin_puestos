class AddRefrenceToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :reference_id_juega, :integer, default: 0
    add_column :propuestas_deportes, :reference_id_banquea, :integer, default: 0
  end
end
