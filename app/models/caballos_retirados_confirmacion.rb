class CaballosRetiradosConfirmacion < ApplicationRecord
  belongs_to :hipodromo
  belongs_to :carrera
  belongs_to :caballos_carrera
  belongs_to :user, optional: true

  enum status: {
    valido: 1,
    retirado: 2,
    invalido: 9
  }

end
