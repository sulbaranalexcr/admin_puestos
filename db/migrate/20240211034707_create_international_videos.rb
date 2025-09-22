class CreateInternationalVideos < ActiveRecord::Migration[5.2]
  def change
    create_table :international_videos do |t|
      t.datetime :date
      t.jsonb :data

      t.timestamps
    end
  end
end
