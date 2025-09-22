class CreateExchangeRates < ActiveRecord::Migration[5.2]
  def change
    create_table :exchange_rates do |t|
      t.jsonb :data

      t.timestamps
    end
  end
end
