class AddPremiadaToPropuestasCaballosPuesto < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_caballos_puestos, :premiada, :boolean,default: false
  end
end
