class AddNextToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :show_next, :boolean, default: false
  end
end
