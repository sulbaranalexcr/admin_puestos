class AddDatosToErroresEnviosApi < ActiveRecord::Migration[5.2]
  def change
    add_column :errores_envios_apis, :liga_id, :integer
    add_column :errores_envios_apis, :match_id, :integer
  end
end
