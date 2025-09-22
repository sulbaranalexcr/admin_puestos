class AddOtroToCuadreGeneralCaballo < ActiveRecord::Migration[5.2]
  def change
    add_column :cuadre_general_caballos, :gano_oc, :float, default: 0
    add_column :cuadre_general_caballos, :perdio_oc, :float, default: 0
    add_column :cuadre_general_caballos, :comision_oc, :float, default: 0
  end
end
