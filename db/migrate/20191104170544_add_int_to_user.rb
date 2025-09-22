class AddIntToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :intermediario_id, :integer
  end
end
