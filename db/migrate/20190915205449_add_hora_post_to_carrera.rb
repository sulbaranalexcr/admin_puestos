class AddHoraPostToCarrera < ActiveRecord::Migration[5.2]
  def change
    add_column :carreras, :hora_pautada, :string
  end
end
