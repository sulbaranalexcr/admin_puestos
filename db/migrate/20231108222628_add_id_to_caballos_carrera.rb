class AddIdToCaballosCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :caballos_carreras, :id_api, :string
  end
end
