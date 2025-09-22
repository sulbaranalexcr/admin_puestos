class AddControlToChat < ActiveRecord::Migration[5.2]
  def change
    add_column :chats, :delivered, :boolean, default: false
    add_column :chats, :for_all, :boolean, default: false
    add_column :chats, :removed, :boolean, default: false
  end
end
