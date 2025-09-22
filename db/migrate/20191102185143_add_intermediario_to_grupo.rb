class AddIntermediarioToGrupo < ActiveRecord::Migration[5.2]
  def change
    add_column :grupos, :intermediario_id, :integer, default: 0
    add_column :grupos, :porcentaje_intermediario, :decimal, default: 0   
  end
end
