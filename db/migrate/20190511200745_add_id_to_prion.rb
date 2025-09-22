class AddIdToPrion < ActiveRecord::Migration[5.2]
  def change
    add_column :premiacions, :id_gana, :integer, default: 0
  end
end
