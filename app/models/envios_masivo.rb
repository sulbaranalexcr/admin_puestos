class EnviosMasivo < ApplicationRecord
  belongs_to :carrera
  belongs_to :integrador

  # Callback para comprimir 'data' antes de guardar
  before_save :comprimir_data

  # Descompresión de los datos al consultar
  module DescompressedRelation
    def exec_queries
      super.each { |record| record.with_descompressed_fields! }
    end
  end

  # Por defecto, aplicar descompresión a las consultas
  def self.default_scope
    all.extending(DescompressedRelation)
  end

  # Scope para consultar los datos comprimidos
  scope :raw_data, -> { unscoped }

  # Método para descomprimir los campos
  def with_descompressed_fields!
    self.data = descomprimir(data) if data.present?
    self
  end

  # Método para comprimir 'data'
  def comprimir_data
    return unless data.present?

    json_data = data.is_a?(String) ? data : data.to_json
    self.data = comprimir(json_data)
  end


  # Métodos para comprimir y descomprimir
  private

  def comprimir(texto)
    deflater = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS)  # Modo raw
    compressed = deflater.deflate(texto, Zlib::FINISH)
    Base64.strict_encode64(compressed)
  ensure
    deflater&.close
  end

def descomprimir(base64)
  return base64 unless base64.is_a?(String)

  begin
    data = Base64.decode64(base64)
    inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    inflater.inflate(data)
  rescue
    base64
  ensure
    inflater&.close
  end
end

  # Método para crear o actualizar el registro
  def self.update_or_create(carrera_id, idi, tipo, objeto_completo)
    record = find_or_initialize_by(carrera_id: carrera_id, integrador_id: idi, type_data: tipo)
    record.data = objeto_completo
    record.save
    record
  end
end
