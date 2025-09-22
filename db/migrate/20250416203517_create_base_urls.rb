class CreateBaseUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :base_urls do |t|
      t.string :gticket
      t.string :pendientes

      t.timestamps
    end
  end
end
