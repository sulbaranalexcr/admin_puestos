class AddPierdeToPropuestasCaballosPuesto < ActiveRecord::Migration[5.2]
  def change
    add_column :propuestas_caballos_puestos, :id_pierde, :integer
  end
end
