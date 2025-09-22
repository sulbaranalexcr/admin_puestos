class AddGanaToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :id_propone, :integer
    add_column :propuestas_deportes, :id_gana, :integer
    add_column :propuestas_deportes, :operaciones_cajero_id, :string 
  end
end
