class AddEntremadorToCaballosCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :caballos_carreras, :entrenador, :string
  end
end
