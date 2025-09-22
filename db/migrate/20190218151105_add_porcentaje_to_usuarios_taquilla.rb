class AddPorcentajeToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :comision, :decimal
  end
end
