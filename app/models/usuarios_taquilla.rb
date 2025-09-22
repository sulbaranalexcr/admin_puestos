class UsuariosTaquilla < ApplicationRecord
  attribute :moneda_default, :integer, default: 2
  attribute :simbolo_moneda_default, :string, default: 'USD'

  has_many :propuestas
  has_many :operaciones_cajeros
  has_one :saldos_iniciodia
  belongs_to :grupo
  belongs_to :integrador, required: false
  has_many :bancos_cliente
  has_many :cuentas_cliente
  has_many :devolucion_sin_saldo_deporte
  has_many :ticket
  scope :cajero_externo, -> { where(usa_cajero_externo: true) }
  scope :externos, -> { where(externo: true) }
  scope :locales, -> { where(externo: false) }

  def valor_moneda
    self.moneda_default_dolar
    # factor = FactorCambio.find_by(grupo_id: self.grupo_id, cobrador_id: self.cobrador_id, moneda_id: self.moneda_default)
    # if factor.present?
    #   factor.valor_dolar.to_f
    # else
    #   1
    # end
  end


end
