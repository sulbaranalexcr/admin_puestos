class AddUserToChat < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :user, foreign_key: true
  end
end
