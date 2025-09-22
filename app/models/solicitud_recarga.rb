class SolicitudRecarga < ApplicationRecord
  belongs_to :usuarios_taquilla
  belongs_to :cuentas_banca
  belongs_to :user, optional: true  
  mount_uploader :imagen, ImagenUploader

   def nombre
     UsuariosTaquilla.find(self.usuarios_taquilla_id).alias
   end

end
