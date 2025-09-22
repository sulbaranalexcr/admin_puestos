class AddCarreraToCuadreGeneralCaballo < ActiveRecord::Migration[5.2]
  def change
    add_column :cuadre_general_caballos, :carrera_id, :integer
    add_column :cuadre_general_caballos, :hipodromo_id, :integer
  end
end
