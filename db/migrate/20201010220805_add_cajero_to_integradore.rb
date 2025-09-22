class AddCajeroToIntegradore < ActiveRecord::Migration[5.2]
  def change
    add_column :integradors, :usa_cajero_externo, :boolean, default: false
  end
end
