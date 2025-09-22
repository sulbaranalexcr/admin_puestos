class CreateMenuUsuarios < ActiveRecord::Migration[5.2]
  def change
    create_table :menu_usuarios do |t|
      t.references :user, foreign_key: true
      t.text :menu

      t.timestamps
    end
  end
end
