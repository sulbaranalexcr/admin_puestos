class AddCOmisionesToOperacionesCajero < ActiveRecord::Migration[5.2]
  def change
    add_column :operaciones_cajeros, :porcentaje_gt, :decimal
    add_column :operaciones_cajeros, :porcentaje_bg, :decimal
  end
end
