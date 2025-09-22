class AddMltoCaballosCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :caballos_carreras, :ml, :string, default: ''
    add_column :caballos_carreras, :o, :float, default: 0
    add_column :caballos_carreras, :us, :integer, default: 0
  end
end
