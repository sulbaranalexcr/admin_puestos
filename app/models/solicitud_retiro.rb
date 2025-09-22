class SolicitudRetiro < ApplicationRecord
  belongs_to :usuarios_taquilla
  belongs_to :cuentas_cliente
  belongs_to :user, optional: true  


  def nombre
    UsuariosTaquilla.find(self.usuarios_taquilla_id).alias
  end


end
