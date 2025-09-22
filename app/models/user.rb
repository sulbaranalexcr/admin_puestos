class User < ApplicationRecord
  has_secure_password
  belongs_to :structure, optional: true
  has_one :external_operator, dependent: :destroy
  has_many :historial_tasa
  # belongs_to :cierre_carrera
  # attr_accessor :password, :repeat_password

  def before_save
    self.username = self.username.downcase
  end

  def is_admin?
    self.user_type == 0 ?  true : false
  end



  def tipo_user
   case self.tipo
   when "INT"
     Intermediario.find(self.intermediario_id).nombre
   when "GRP"
     Grupo.find(self.grupo_id).nombre
   when "COB"
     Cobradore.find(self.cobrador_id).nombre_completo
   when "ADM"
     "BANCA"
   end

  end

  # def repeat_password
  #   '******'
  # end
  #
  # def password
  #   '******'
  # end
end
