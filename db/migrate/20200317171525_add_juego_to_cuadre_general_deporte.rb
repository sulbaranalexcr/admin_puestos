class AddJuegoToCuadreGeneralDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :cuadre_general_deportes, :juego_id, :integer
    add_column :cuadre_general_deportes, :match_id, :integer
  end
end
