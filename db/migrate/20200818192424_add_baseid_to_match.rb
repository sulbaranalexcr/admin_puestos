class AddBaseidToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :id_base, :integer
  end
end
