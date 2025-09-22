class CreateCaballosRetiradosConfirmacions < ActiveRecord::Migration[5.2]
  def change
    create_table :caballos_retirados_confirmacions do |t|
      t.references :hipodromo, foreign_key: true
      t.references :carrera, foreign_key: true
      t.references :caballos_carrera, foreign_key: true
      t.integer :status
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
