class AddCompositeIndexToPropuestasCaballosPuestos < ActiveRecord::Migration[7.1]
  def change
    add_index :propuestas_caballos_puestos, 
              [:created_at, :status, :status2, :id_propone, :id_juega, :id_banquea, :caballos_carrera_id], 
              name: 'index_on_frequent_query'
  end
end
