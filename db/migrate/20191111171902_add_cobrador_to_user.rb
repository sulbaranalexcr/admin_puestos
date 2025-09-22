class AddCobradorToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :cobrador_id, :integer
  end
end
