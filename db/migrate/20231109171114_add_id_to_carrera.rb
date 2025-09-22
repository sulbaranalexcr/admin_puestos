class AddIdToCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :carreras, :id_api, :string
  end
end
