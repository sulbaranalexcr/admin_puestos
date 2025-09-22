class AddIntegradorToRetornosBloqueApi < ActiveRecord::Migration[5.2]
  def change
    add_column :retornos_bloque_apis, :integrador_id, :integer, default: 0
  end
end
