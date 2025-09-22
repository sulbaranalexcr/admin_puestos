class AddReportesToCuadreGeneralDeporte < ActiveRecord::Migration[5.2]
  def change
    add_column :cuadre_general_deportes, :monto_otro_grupo, :float
    add_column :cuadre_general_deportes, :gano_oc, :float
    add_column :cuadre_general_deportes, :perdio_oc, :float
    add_column :cuadre_general_deportes, :comision_oc, :float
  end
end
