class AddMonedaToCobradore < ActiveRecord::Migration[5.2]
  def change
    add_reference :cobradores, :moneda, foreign_key: true
  end
end
