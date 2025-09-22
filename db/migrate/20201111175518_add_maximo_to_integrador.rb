class AddMaximoToIntegrador < ActiveRecord::Migration[5.2]
  def change
    add_column :integradors, :min_und, :float, default: 0
    add_column :integradors, :max_und, :float, default: 0
  end
end
