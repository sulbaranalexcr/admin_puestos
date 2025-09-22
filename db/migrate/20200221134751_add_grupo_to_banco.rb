class AddGrupoToBanco < ActiveRecord::Migration[5.2]
  def change
    add_column :bancos, :grupo_id, :integer, default: 0
  end
end
