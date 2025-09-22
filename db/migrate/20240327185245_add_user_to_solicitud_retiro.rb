class AddUserToSolicitudRetiro < ActiveRecord::Migration[7.1]
  def change
    add_column :solicitud_retiros, :user_id, :integer
  end
end
