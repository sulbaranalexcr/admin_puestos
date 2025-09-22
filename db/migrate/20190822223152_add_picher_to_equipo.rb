class AddPicherToEquipo < ActiveRecord::Migration[5.2]
  def change
    add_column :equipos, :picher, :string
  end
end
