class AddVendeGanadoresToCobradore < ActiveRecord::Migration[5.2]
  def change
    add_column :cobradores, :vende_ganadores, :boolean, default: false
  end
end
