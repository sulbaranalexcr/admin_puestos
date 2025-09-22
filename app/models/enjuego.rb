class Enjuego < ApplicationRecord
  belongs_to :propuesta
  belongs_to :usuarios_taquilla
  include ApplicationHelper

  def propuesta
    Propuesta.find(self.propuesta_id)
  end

  def status_propuesta()
    text_status2(self.status2)
  end

end
