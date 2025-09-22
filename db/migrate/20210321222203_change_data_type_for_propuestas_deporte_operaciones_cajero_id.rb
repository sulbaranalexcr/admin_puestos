class ChangeDataTypeForPropuestasDeporteOperacionesCajeroId < ActiveRecord::Migration[5.2]
  def self.up
    change_column :propuestas_deportes, :operaciones_cajero_id, "integer USING CAST(operaciones_cajero_id AS integer)"
  end
end



