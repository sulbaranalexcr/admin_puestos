class CreateApps < ActiveRecord::Migration[5.2]
  def change
    create_table :apps do |t|
      t.string :nombre

      t.timestamps
    end
  end
end
