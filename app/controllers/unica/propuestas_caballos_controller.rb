# frozen_string_literal: true

module Unica
  # propuestas utilidades
  class PropuestasCaballosController < ApplicationController
    skip_before_action :verify_authenticity_token

    def setear_usuarios
      @users_local = [
        ['generadorpropuestas@unpuesto.com', 'vergatarios', 0, true],
        ['generadorusd@unpuesto.com', 'vergatarios', 1, true],
        ['generadorabd@unpuesto.com', 'vergatarios', 2, true]
      ]
      @users_jel = [['rafaelrams@hotmail.com', '123456', 0, false]]
    end

    def index
      @carreras = []
      setear_usuarios
      redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      config_users_locals = redis.get('config_users_locals')
      config_users_jel = redis.get('config_users_jel')
      @users_local = JSON.parse(config_users_locals) if config_users_locals.present?
      @users_jel = JSON.parse(config_users_jel) if config_users_locals.present?

      Jornada.where(fecha: Time.now.all_day, hipodromo_id: Hipodromo.where(activo: true).ids).each do |jornada|
        carreras = Carrera.where(jornada_id: jornada.id, activo: true).order(:id)
                          .pluck(:id, :numero_carrera, :hora_pautada)
        carreras.each do |carrera|
          @carreras << insertar_carrera(jornada, carrera)
        end
      end
    end

    def insertar_carrera(jornada, carrera)
      {
        carrera_id: carrera[0],
        numero_carrera: carrera[1],
        hora_carrera: carrera[2],
        nombre_hipodromo: jornada.hipodromo.nombre
      }
    end

    def crear_caballos
      @caballos_array = []
      caballos = CaballosCarrera.where(carrera_id: params[:id]).order("to_number(numero_puesto,'99')")
      caballos.each do |cab|
        @caballos_array << insertar_caballo(cab)
      end
      render partial: 'unica/propuestas_caballos/caballos', layout: false
    end

    def insertar_caballo(cab)
      {
        id: cab.id,
        numero_puesto: cab.numero_puesto,
        nombre: cab.nombre,
        retirado: cab.retirado
      }
    end

    def crear_propuestas
      carrera_id = params[:id]
      users = params[:users]
      caballos = params[:caballos]
      favoritos = caballos.select { |a| a['ml'].to_f <= 6 }.count
      redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      setear_usuarios
      @users_local.each do |user|
        user[3] = users['locals'].find { |a| a['id'] == user[2].to_s }['checked']
      end

      @users_jel.each do |user|
        user[3] = users['jel'].find { |a| a['id'] == user[2].to_s }['checked']
      end

      redis.set('config_users_locals', @users_local)
      redis.set('config_users_jel', @users_jel)

      envia_usuario_jel = redis.get('usuario_jel_pase')
      cantidada_corriendo = CaballosCarrera.where(retirado: false, carrera_id: carrera_id).count
      @propuestas = []
      # usuarios = [['generadorpropuestas@unpuesto.com', 'vergatarios'], ['generadorusd@unpuesto.com', 'vergatarios'], ['generadorabd@unpuesto.com', 'vergatarios']]
      caballos.each do |caballo|
        ml = caballo['ml'].to_f
        [1, 2, 3].each do |vuelta|
          monto = params[:monto].to_f
          banquean, juegan = if cantidada_corriendo == 4
                               ParametrosPropuestas::Condiciones.cuatro_caballos(ml, vuelta)
                             elsif cantidada_corriendo == 5
                               ParametrosPropuestas::Condiciones.cinco_caballos(ml, vuelta)
                             elsif cantidada_corriendo >= 6 && favoritos == 1
                               ParametrosPropuestas::Condiciones.seis_caballos1(ml, vuelta)
                             elsif cantidada_corriendo >= 6 && favoritos == 2
                               ParametrosPropuestas::Condiciones.seis_caballos2(ml, vuelta)
                             elsif cantidada_corriendo >= 6 && favoritos >= 3
                               ParametrosPropuestas::Condiciones.seis_caballos3(ml, vuelta)
                             else
                               [0, 0]
                             end
          banquean_ml, juegan_ml, monto_apuesta = ParametrosPropuestas::Condiciones.parametros_ml(ml, monto, vuelta)
          case vuelta
          when 2
            monto *= 1.5
            monto_apuesta *= 1.5
          when 3
            monto *= 2
            monto_apuesta *= 2
          end
          @propuestas << { caballo_id: caballo['id'], banquean: banquean, juegan: juegan, banquean_ml: banquean_ml, juegan_ml: juegan_ml, monto: monto, monto_propuesta: monto_apuesta }
        end
        generar_jel_propuestas(cantidada_corriendo, ml, favoritos, caballo) if envia_usuario_jel.present?
      end
      @users_local.each do |usuario|
        GenerarPropuestasCaballosJob.perform_async(usuario, @propuestas) if usuario[3]
      end
      return unless envia_usuario_jel.present?

      # usuario_jel = ['rafaelrams@hotmail.com', '123456']
      @users_jel.each do |usuario|
        GenerarPropuestasCaballosJob.perform_async(usuario_jel, @propuestas) if usuario[3]
      end
    end

    def generar_jel_propuestas(cantidada_corriendo, ml, favoritos, caballo)
      monto = params[:monto].to_f
      banquean, juegan = if cantidada_corriendo == 4
                           ParametrosPropuestasJel::Condiciones.cuatro_caballos(ml)
                         elsif cantidada_corriendo == 5
                           ParametrosPropuestasJel::Condiciones.cinco_caballos(ml)
                         elsif cantidada_corriendo >= 6 && favoritos == 1
                           ParametrosPropuestasJel::Condiciones.seis_caballos1(ml)
                         elsif cantidada_corriendo >= 6 && favoritos == 2
                           ParametrosPropuestasJel::Condiciones.seis_caballos2(ml)
                         elsif cantidada_corriendo >= 6 && favoritos >= 3
                           ParametrosPropuestasJel::Condiciones.seis_caballos3(ml)
                         else
                           [0, 0]
                         end
      @propuestas << { caballo_id: caballo['id'], banquean: banquean, juegan: juegan, banquean_ml: 0, juegan_ml: 0, monto: monto, monto_propuesta: 0 }
    end
  end
end
