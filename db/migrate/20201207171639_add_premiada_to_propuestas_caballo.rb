class AddPremiadaToPropuestasCaballo < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_caballos, :premiada, :boolean,default: false
  end
end
