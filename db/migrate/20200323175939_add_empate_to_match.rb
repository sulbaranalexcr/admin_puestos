class AddEmpateToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :usa_empate, :boolean, default: false
  end
end
