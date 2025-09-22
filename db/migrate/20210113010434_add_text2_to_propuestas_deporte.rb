class AddText2ToPropuestasDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_deportes, :texto_igual_condicion, :string, default: '' 
  end
end
