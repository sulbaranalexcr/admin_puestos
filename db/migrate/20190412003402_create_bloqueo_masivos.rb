class CreateBloqueoMasivos < ActiveRecord::Migration[5.2]
  def change
    create_table :bloqueo_masivos do |t|
      t.boolean :activo, default: false

      t.timestamps
    end
  end
end
