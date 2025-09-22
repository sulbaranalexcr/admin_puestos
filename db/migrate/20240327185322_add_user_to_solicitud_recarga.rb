class AddUserToSolicitudRecarga < ActiveRecord::Migration[7.1]
  def change
    add_column :solicitud_recargas, :user_id, :integer
  end
end
