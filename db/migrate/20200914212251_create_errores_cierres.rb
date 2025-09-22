class CreateErroresCierres < ActiveRecord::Migration[5.2]
  def change
    create_table :errores_cierres do |t|
      t.text :mensaje
      t.text :mensaje2
      t.text :parametros

      t.timestamps
    end
  end
end
