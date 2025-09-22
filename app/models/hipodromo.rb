class Hipodromo < ApplicationRecord
include ApplicationHelper
  # has_many :carrera, dependent: :destroy
  has_many :jornada, dependent: :destroy
  after_update :send_channel

  def send_channel
    return if saved_change_to_cierre_api?

    ActionCable.server.broadcast 'publicas_deporte_channel',
    { data: { 'tipo' => 'UPDATE_HIPODROMO', 'data_menu' => menu_hipodromos_helper,
    'hip_id' => self.id }}
  end
end