class AddDataToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :data, :text
  end
end
