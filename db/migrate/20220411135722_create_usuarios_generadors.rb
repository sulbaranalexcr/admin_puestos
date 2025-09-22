class CreateUsuariosGeneradors < ActiveRecord::Migration[5.2]
  def change
    create_table :usuarios_generadors do |t|
      t.string :correo
      t.string :clave
      t.float :porcentaje

      t.timestamps
    end
  end
end
