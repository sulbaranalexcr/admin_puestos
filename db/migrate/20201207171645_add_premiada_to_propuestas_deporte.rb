class AddPremiadaToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :premiada, :boolean,default: false
  end
end
