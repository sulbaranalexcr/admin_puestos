class AddTipoToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :tipo, :string
  end
end
