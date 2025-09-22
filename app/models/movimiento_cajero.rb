class MovimientoCajero < ApplicationRecord
  belongs_to :usuarios_taquilla
  belongs_to :user

  enum type_operation: { 'Deposito' => 1, 'Retiro' => 2 }
end
