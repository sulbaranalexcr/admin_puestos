class AddMontoToPremiacion < ActiveRecord::Migration[5.2]
  def change
    add_column :premiacions, :monto_pagado_completo, :decimal
  end
end
