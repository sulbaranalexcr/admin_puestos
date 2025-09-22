class AddComisionToCobradore < ActiveRecord::Migration[5.2]
  def change
    add_column :cobradores, :comision_banca, :float, default: 0
    add_column :cobradores, :comision_integrador, :float, default: 0
    add_column :cobradores, :comision_grupo, :float, default: 0
  end
end
