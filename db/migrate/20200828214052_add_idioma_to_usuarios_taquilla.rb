class AddIdiomaToUsuariosTaquilla < ActiveRecord::Migration[5.2]
  def change
    add_column :usuarios_taquillas, :idioma, :string, default: 'es'
  end
end
