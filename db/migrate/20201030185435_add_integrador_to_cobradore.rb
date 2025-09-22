class AddIntegradorToCobradore < ActiveRecord::Migration[5.2]
  def change
    add_column :cobradores, :integrador_id, :integer
  end
end
