class MontogrupoToCuadreGeneralCaballo < ActiveRecord::Migration[5.2]
  def change
      add_column :cuadre_general_caballos, :monto_otro_grupo, :float
  end
end
