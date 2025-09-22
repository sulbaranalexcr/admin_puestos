class AddIdGoalToHipodromo < ActiveRecord::Migration[5.2]
  def change
    add_column :hipodromos, :id_goal, :string
  end
end
