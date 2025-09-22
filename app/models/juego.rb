class Juego < ApplicationRecord
  mount_uploader :imagen, ImagenUploader
  has_many :liga
end
