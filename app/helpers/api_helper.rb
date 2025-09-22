module ApiHelper
  def comprimir(texto)
    deflater = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS) # modo raw
    compressed = deflater.deflate(texto, Zlib::FINISH)
    Base64.strict_encode64(compressed)
  end

  def descomprimir(base64)
    data = Base64.decode64(base64)
    inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    inflater.inflate(data)
  end

  def obtener_saldo_cajero_externo(integrador_id, user_id  = 0, token)
      integrador = Integrador.find(integrador_id)
      datos_cajero = JSON.parse(integrador.datos_cajero_integrador.datos_cajero)
      url = datos_cajero['obtener_saldo']['url']
      metodo = datos_cajero['obtener_saldo']['metodo']
      headers = datos_cajero['obtener_saldo']['parametros_header']
      body = datos_cajero['obtener_saldo']['parametros_body']
      rspuesta = conectarse_integrador(url, metodo, headers, body, user_id, token, integrador_id)
      respuesta = JSON.parse(rspuesta)
      if eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_i == 200 or eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_s.upcase == "OK"
        return eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['saldo']}")
      else
        ErroresCajeroExterno.create(user_id: user_id, transaction_id: -1, amount: monto, message: eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}"))
        return -99
      end
  end

  def debitar_saldo_cajero_externo(integrador_id, user_id  = 0, token, monto, mensaje, operacion_id)
      integrador = Integrador.find(integrador_id)
      datos_cajero = JSON.parse(integrador.datos_cajero_integrador.datos_cajero)
      url = datos_cajero['debitar_saldo']['url']
      metodo = datos_cajero['debitar_saldo']['metodo']
      headers = datos_cajero['debitar_saldo']['parametros_header']
      body = datos_cajero['debitar_saldo']['parametros_body']
      rspuesta = conectarse_integrador(url,metodo, headers,body,user_id, token, integrador_id, monto, mensaje, operacion_id )
      respuesta = JSON.parse(rspuesta)
      if eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_i == 200 or eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_s.upcase == "OK"
        return eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['saldo']}")
      else
        ErroresCajeroExterno.create(user_id: user_id, transaction_id: operacion_id, amount: monto, message: eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}"))
        return -99
      end
  end


  def acreditar_saldo_cajero_externo(integrador_id, user_id  = 0, token, monto, mensaje, operacion_id,tipo_op)
      integrador = Integrador.find(integrador_id)
      datos_cajero = JSON.parse(integrador.datos_cajero_integrador.datos_cajero)
      url = datos_cajero['acreditar_saldo']['url']
      metodo = datos_cajero['acreditar_saldo']['metodo']
      headers = datos_cajero['acreditar_saldo']['parametros_header']
      body = datos_cajero['acreditar_saldo']['parametros_body']
      rspuesta = conectarse_integrador(url,metodo, headers,body,user_id, token, integrador_id, monto, mensaje, operacion_id,tipo_op )
      respuesta = JSON.parse(rspuesta)
      if eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_i == 200 or eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}").to_s.upcase == "OK"
        return eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['saldo']}")
      else
        ErroresCajeroExterno.create(user_id: user_id, transaction_id: operacion_id, amount: monto, message: eval("respuesta#{datos_cajero['obtener_saldo']['retorno']['estado']}"))
        return -99
      end
  end


  def acreditar_saldos_cajero_externo(integrador_id, datos, hipodromo_id, carrera_id, tipo_operacion, reintentos = 0)
    begin
      integrador = Integrador.find(integrador_id)
      datos_cajero = JSON.parse(integrador.datos_cajero_integrador.datos_cajero)
      url = datos_cajero['acreditar_saldo_bloque']['url']
      metodo = datos_cajero['acreditar_saldo_bloque']['metodo']
      headers = datos_cajero['acreditar_saldo_bloque']['parametros_header']
      body = datos_cajero['acreditar_saldo_bloque']['parametros_body']
      rspuesta = conectarse_integrador_bloque(url, datos, integrador_id )
      respuesta = descomprimir(JSON.parse(rspuesta)['data'])
      RetornosBloqueApi.create(integrador_id: integrador_id, tipo: tipo_operacion, hipodromo_id: hipodromo_id, carrera_id: carrera_id, data_enviada: datos.to_json, data_recibida: respuesta, procesada: true, reintento: false)
      Rails.logger.info "*******************************aqui verifico"
      # Rails.logger.info respuesta['users'].count != JSON.parse(datos.to_json)['users'].count
      # if respuesta['users'].count != JSON.parse(datos.to_json)['users'].count
      #   Rails.logger.info "*******************************reintentando por diferencia"
      #   # raise "Error al acreditar saldos, diferencia de users"
      # end
    rescue StandardError => e
      Rails.logger.info e
      ErroresEnviosApi.create(integrador_id: integrador_id, tipo: tipo_operacion, hipodromo_id: hipodromo_id, carrera_id: carrera_id, mensaje: e.message, mensaje2: e.backtrace.inspect, status: 1)
      # raise e
    end
  end

  def conectarse_integrador(url, tipo, parametros_header, parametros_body,user_id, token, integrator_id, monto = 0, mensaje = "", operacion_id = 0,tipo_op = 0)
      parametros = Hash.newconectarse_integrador_bloque
      parametros_body.each{|tpb|
        tpb.each{|pb, value|
          if value == "user_id"
            parametros[pb] = user_id
          elsif value == "token"
            parametros[pb] = token
          elsif value == "monto"
            parametros[pb] = monto
          elsif value == "detalle"
            parametros[pb] = mensaje
#          elsif value == "transaction_id"
            #parametros[pb] = operacion_id
          elsif value == "credit"
            parametros[pb] = tipo_op
          else
            parametros[pb] = value
          end
        }
      }


      require 'net/http'
      require 'uri'
      parametros.merge(integrator_id: integrator_id)
      response = Net::HTTP.post URI(url),
                    parametros.to_json,
                    "Content-Type" => "application/json"
      return response.body
  end

  def conectarse_integrador_bloque(url, parametros, integrator_id)
    require 'net/http'
    require 'uri'
    logger.info("***************OJO envio al cajero************************************")
    logger.info(parametros)
    logger.info("**********************************************************************")

    if url.include?('https')
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 181 # seconds
      http.use_ssl = true
      http.ssl_version = :TLSv1_2
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      payload = { data: comprimir(parametros.to_json) }.to_json
      response = http.post(uri.request_uri, payload, 'Content-Type' => 'application/json')
      logger.info("***************OJO respondio el  cajero************************************")
      logger.info(response.body)
      logger.info("**********************************************************************")
      response.body

    else  
      url = URI.parse(url)
      http = Net::HTTP.new(url.host, url.port)
      http.read_timeout = 181 # seconds
      payload = { data: comprimir(parametros.to_json) }.to_json
      http.request_post(url.path, payload, 'Content-Type' => 'application/json') do |response|
      logger.info("***************OJO respondio el  cajero************************************")
      logger.info(response.body)
      logger.info("**********************************************************************")
        return response.body
      end
    end
  end
end





