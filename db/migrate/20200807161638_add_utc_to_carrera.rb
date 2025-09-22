class AddUtcToCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :carreras, :utc, :string
  end
end
