class ChangeNumeroPuestoToBeStringInCaballosCarrera < ActiveRecord::Migration[5.2]

  def up
    change_column :caballos_carreras, :numero_puesto, :string
  end

  def down
    change_column :caballos_carreras, :numero_puesto, :integer
  end

end
