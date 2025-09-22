class AddMonedaToPremiacion < ActiveRecord::Migration[5.2]
  def change
    add_column :premiacions, :moneda, :integer
  end
end
