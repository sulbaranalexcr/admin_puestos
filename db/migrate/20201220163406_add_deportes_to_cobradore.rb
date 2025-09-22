class AddDeportesToCobradore < ActiveRecord::Migration[5.2]
  def change
    add_column :cobradores, :deporte_id, :string, default: '[]'
  end
end
