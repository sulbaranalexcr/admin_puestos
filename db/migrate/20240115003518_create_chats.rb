class CreateChats < ActiveRecord::Migration[5.2]
  def change
    create_table :chats do |t|
      t.integer :grupo_id
      t.jsonb :message

      t.timestamps
    end
  end
end
