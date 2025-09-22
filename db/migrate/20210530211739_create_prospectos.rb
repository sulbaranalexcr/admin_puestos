class CreateProspectos < ActiveRecord::Migration[5.2]
  def change
    create_table :prospectos do |t|
      t.text :url

      t.timestamps
    end
  end
end
