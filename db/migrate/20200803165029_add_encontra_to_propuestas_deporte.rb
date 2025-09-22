class AddEncontraToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :equipo_contra, :integer, default: 0
  end
end
