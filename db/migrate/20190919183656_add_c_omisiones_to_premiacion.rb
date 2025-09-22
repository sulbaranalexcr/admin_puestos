class AddCOmisionesToPremiacion < ActiveRecord::Migration[5.2]
  def change
    add_column :premiacions, :porcentaje_gt, :decimal
    add_column :premiacions, :porcentaje_bg, :decimal
  end
end
