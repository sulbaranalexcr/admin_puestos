class CreatePropuestasCaballos < ActiveRecord::Migration[5.2]
  def change
    create_table :propuestas_caballos do |t|
      t.integer :deporte_id, default: 998
      t.integer :hipodromo_id, default: 0
      t.integer :carrera_id, default: 0
      t.integer :caballos_carrera_id, default: 0
      t.integer :tipo_apuesta_id, default: 0
      t.string :puesto, default: ''
      t.integer :accion_id, default: 0
      t.integer :tipo_apuesta, default: 1
      t.float :logro, default: 0
      t.float :monto, default: 0
      t.integer :id_juega, default: 0
      t.integer :id_banquea, default: 0
      t.integer :id_propone, default: 0
      t.integer :id_gana, default: 0 
      t.float :cuanto_gana, default: 0
      t.float :cuanto_gana_completo
      t.float :cuanto_pierde
      t.integer :status, default: 1
      t.integer :status2, default: 1
      t.boolean :activa, default: true
      t.integer :id_padre, default: 0
      t.integer :moneda, default: 1
      t.integer :grupo_id, default: 0
      t.boolean :cruzo_igual_accion
      t.string :texto_cruzado, default: ''
      t.integer :operaciones_cajero_id, default: 0 
      t.integer :corte_id, default: 0 
      t.integer :tipo_juego, default: 1
       
      t.timestamps
    end
  end
end
