class CreateErroresSistemas < ActiveRecord::Migration[5.2]
  def change
    create_table :errores_sistemas do |t|
      t.integer :app
      t.string :app_detalle
      t.string :error
      t.text :detalle
      t.integer :nivel
      t.boolean :reportado
      t.integer :usuario_reporta
      t.timestamps
    end
  end
end
