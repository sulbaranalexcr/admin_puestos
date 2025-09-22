class AddToolsToCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :carreras, :distance, :string
    add_column :carreras, :name, :string
    add_column :carreras, :purse, :string
    add_column :carreras, :results, :jsonb
  end
end
