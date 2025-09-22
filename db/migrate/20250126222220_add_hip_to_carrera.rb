class AddHipToCarrera < ActiveRecord::Migration[7.1]
  def change
    add_column :carreras, :hipodromo_id, :integer
    add_column :carreras, :hipodromo_name, :string
  end
end
