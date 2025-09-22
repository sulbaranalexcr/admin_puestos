class CreatePropuetasCaballosPuestos < ActiveRecord::Migration[5.2]
  def change
    create_table :propuestas_caballos_puestos do |t|
      t.references :grupo, foreign_key: true
      t.references :hipodromo, foreign_key: true
      t.references :carrera, foreign_key: true
      t.references :caballos_carrera, foreign_key: true
      t.string :puesto, default: ''
      t.integer :accion_id
      t.references :tipo_apuesta, foreign_key: true
      t.string :tipo_puesto_nombre, default: ''
      t.string :texto_jugada, default: ''
      t.integer :moneda, default: 2
      t.decimal :monto
      t.integer :id_propone, default: 0
      t.integer :id_juega, default: 0
      t.integer :id_banquea, default: 0
      t.integer :id_gana, default: 0
      t.decimal :cuanto_gana, default: 0
      t.decimal :cuanto_gana_completo, default: 0
      t.decimal :cuanto_pierde, default: 0
      t.integer :status, default: 0
      t.integer :status2, default: 0
      t.boolean :activa, default: true
      t.integer :id_padre, default: 0
      t.integer :corte_id, default: 0
      t.integer :tipo_juego, default: 3
      t.references :operaciones_cajero, foreign_key: true

      t.timestamps
    end
  end
end
