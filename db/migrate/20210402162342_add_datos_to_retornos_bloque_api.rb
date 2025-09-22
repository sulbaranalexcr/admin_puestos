class AddDatosToRetornosBloqueApi < ActiveRecord::Migration[5.2]
  def change
    add_column :retornos_bloque_apis, :liga_id, :integer
    add_column :retornos_bloque_apis, :match_id, :integer
  end
end
