class AddTipoToOperacionesCajero < ActiveRecord::Migration[5.2]
  def change
    add_column :operaciones_cajeros, :tipo, :integer, default: 0
  end
end
