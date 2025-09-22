class AddTipoappToOperacionesCajero < ActiveRecord::Migration[5.2]
  def change
    add_column :operaciones_cajeros, :tipo_app, :integer, default: 1
  end
end
