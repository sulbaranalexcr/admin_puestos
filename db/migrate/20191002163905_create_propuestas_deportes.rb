class CreatePropuestasDeportes < ActiveRecord::Migration[5.2]
  def change
    create_table :propuestas_deportes do |t|
      t.integer :deporte_id, default: 0
      t.integer :liga_id, default: 0
      t.integer :match_id, default: 0
      t.integer :equipo_id, default: 0
      t.integer :accion_id, default: 0
      t.integer :tipo_apuesta, default: 0
      t.float :logro, default: 0
      t.float :monto, default: 0
      t.float :carreras_dadas, default: 0
      t.float :alta_baja, default: 0
      t.integer :tipo_altabaja, default: 0
      t.integer :id_juega, default: 0
      t.integer :id_banquea, default: 0
      t.float :cuanto_gana, default: 0
      t.float :cuanto_gana_completo
      t.integer :status, default: 1
      t.integer :status2, default: 1
      t.boolean :activa, default: true
      t.integer :id_padre, default: 0
      t.integer :moneda, default: 1
      t.integer :grupo_id, default: 0

      t.timestamps
    end
  end
end
