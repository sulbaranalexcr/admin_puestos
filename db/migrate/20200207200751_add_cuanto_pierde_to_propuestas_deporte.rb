class AddCuantoPierdeToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :cuanto_pierde, :float
    add_column :propuestas_deportes, :cruzo_igual_accion, :boolean, default: false
    add_column :propuestas_deportes, :texto_cruzado, :string
  end
end
