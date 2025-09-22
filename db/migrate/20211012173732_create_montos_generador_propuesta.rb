class CreateMontosGeneradorPropuesta < ActiveRecord::Migration[5.2]
  def change
    create_table :montos_generador_propuesta do |t|
      t.jsonb :data

      t.timestamps
    end
  end
end
