class CreateErroresTaquillaVenta < ActiveRecord::Migration[5.2]
  def change
    create_table :errores_taquilla_venta do |t|
      t.integer :producto
      t.text :error
      t.jsonb :data
      t.integer :usuarios_taquilla_id

      t.timestamps
    end
  end
end
