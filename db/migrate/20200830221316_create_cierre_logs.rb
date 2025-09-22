class CreateCierreLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :cierre_logs do |t|
      t.text :parametros

      t.timestamps
    end
  end
end
