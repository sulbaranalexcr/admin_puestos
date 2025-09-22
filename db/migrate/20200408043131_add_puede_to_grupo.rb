class AddPuedeToGrupo < ActiveRecord::Migration[5.2]
  def change
    add_column :grupos, :propone, :boolean, default: true
    add_column :grupos, :toma, :boolean, default: true
  end
end
