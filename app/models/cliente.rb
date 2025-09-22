class Cliente < ApplicationRecord
  has_many :bancos_cliente, dependent: :destroy
end
