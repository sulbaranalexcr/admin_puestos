class RetornosBloqueApi < ApplicationRecord
  # === Descompresión automática al consultar ===
  module DescompressedRelation
    def exec_queries
      super.each { |record| record.with_descompressed_fields! }
    end
  end

  # Por defecto se extiende la relación con la lógica de descompresión
  def self.default_scope
    all.extending(DescompressedRelation)
  end

  # === Scope para consultar sin descomprimir (eliminando completamente el default_scope) ===
  scope :raw_data, -> { unscoped }

  # === Callbacks para compresión automática ===
  before_save :comprimir_campos

  # === Métodos ===

  def with_descompressed_fields!
    self.data_enviada = descomprimir(data_enviada) if data_enviada.present?
    self.data_recibida = descomprimir(data_recibida) if data_recibida.present?
    self
  end

  private

  def comprimir(texto)
    deflater = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS)
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

  def comprimir_campos
    self.data_enviada = comprimir(data_enviada) if data_enviada.present?
    self.data_recibida = comprimir(data_recibida) if data_recibida.present?
  end
end



  # Método para comprimir 'data'
  def comprimir(texto)
    deflater = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS)  # Modo raw
    compressed = deflater.deflate(texto, Zlib::FINISH)
    Base64.strict_encode64(compressed)
  ensure
    deflater&.close
  end


