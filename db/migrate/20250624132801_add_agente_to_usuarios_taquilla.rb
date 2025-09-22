class AddAgenteToUsuariosTaquilla < ActiveRecord::Migration[7.1]
  def change
    add_column :usuarios_taquillas, :id_agente, :string, default: ''
  end
end
