class AddTipoLogroToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :tipo_logro, :string, default: 'us'
  end
end
