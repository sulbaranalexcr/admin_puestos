# frozen_string_literal: true

module ParametrosPropuestasDeporte
  # clase para hipodromos
  class Condiciones
    def self.propuestas(valor, deporte, tipo, monto)
      @redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      case deporte.to_i
      when 4, 16 # baseball
        tipo_baseball(4, tipo, valor, monto)
      when 12 # soccer
        tipo_soccer(12, tipo, valor, monto)
      when 1, 5 # basket
        tipo_basket(5, tipo, valor, monto)
      end
    end

    def self.tipo_basket(deporte, tipo, valor, monto)
      case tipo.to_i
      when 1 # money_line
        extract_redis_data(deporte, 'money_line', valor, monto)
      when 2 # runline
        extract_redis_data(deporte, 'run_line', valor, monto)
      when 3 # altabaja
        extract_redis_data(deporte, 'alta_baja', valor, monto)
      else
        [0, 0, 0]
      end
    end

    def self.tipo_baseball(deporte, tipo, valor, monto)
      case tipo.to_i
      when 1 # money_line
        extract_redis_data(deporte, 'money_line', valor, monto)
      when 2 # runline
        extract_redis_data(deporte, 'run_line', valor, monto)
      when 3 # altabaja
        extract_redis_data(deporte, 'alta_baja', valor, monto)
      else
        [0, 0, 0]
      end
    end

    def self.tipo_soccer(deporte, tipo, valor, monto)
      case tipo.to_i
      when 1 # money_line
        extract_redis_data(deporte, 'money_line', valor, monto)
      when 3 # altabaja
        extract_redis_data(deporte, 'alta_baja', valor, monto)
      else
        [0, 0, 0]
      end
    end

    def self.calculo_logro(valor, monto, factorbanquea, factorjuego)
      [
        factorbanquea.zero? ? 0 : calcular_factor_logro(valor, factorbanquea),
        factorjuego.zero? ? 0 : calcular_factor_logro(valor, factorjuego),
        monto
      ]
    end

    def self.calcular_factor_logro(valor, factor)
      return 0 if valor.zero?
      return valor if factor == 1
      return (valor + factor) if valor >= 100

      if (valor + factor) >= -101
        (100 - (valor.abs - 100)) + factor
      elsif (valor + factor) < -101
        valor + factor
      else
        0
      end
    end

    def self.extract_redis_data(deporte, method, valor, monto)
      data = JSON.parse(@redis.hget('parametros', deporte))
      return [0, 0, 0] unless data.present?

      data_default = []
      search = data[method]
      return [0, 0, 0] if search.blank?

      search.each do |sea|
        next unless find_header(valor, sea['header']).present?

        data_default = calculo_logro(valor, monto, sea['data']['banquear'].to_i, sea['data']['jugar'].to_i)
      end

      data_default.blank? ? [0, 0, 0] : data_default
    end

    def self.find_header(valor, header)
      valor.between?(header[0].to_i, header[1].to_i)
    end
  end
end
