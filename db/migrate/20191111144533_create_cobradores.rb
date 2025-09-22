class CreateCobradores < ActiveRecord::Migration[5.2]
  def change
    create_table :cobradores do |t|
      t.string :nombre
      t.string :apellido
      t.string :correo
      t.string :telefono
      t.references :grupo, foreign_key: true
      t.text :usuarios_taquilla_id
      t.boolean :activo

      t.timestamps
    end
  end
end
