module Unica
  class GeneradorPropuestasController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      @juegos = Juego.where(juego_id: [4, 5, 12]).order(:nombre)
    end

    def show
      redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
      data_redis = redis.hget('parametros', params[:id].to_i)
      render json: { sport: params[:id].to_i, data: new_data(params[:id].to_i) } and return if data_redis.blank?

      render json: { sport: params[:id].to_i, data: JSON.parse(data_redis) }
    end

    def save_parameters
      Redis.new(host: Figaro.env.REDIS_HOST, port: 6379).hset('parametros', params[:sport_id], params[:data].to_json)
      render json: { msg: 'OK' }
    end

    def new_data(sport_id)
      case sport_id
      when 4, 5
        data_with_runline
      when 12
        {
          'money_line' => [{ 'header' => [0, 0], 'data' => { 'banquear' => 0, 'jugar' => 0 } }],
          'alta_baja' => [{ 'header' => [0, 0], 'data' => { 'banquear' => 0, 'jugar' => 0 } }]
        }
      end
    end

    def data_with_runline
      {
        'money_line' => [{ 'header' => [0, 0], 'data' => { 'banquear' => 0, 'jugar' => 0 } }],
        'run_line' => [{ 'header' => [0, 0], 'data' => { 'banquear' => 0, 'jugar' => 0 } }],
        'alta_baja' => [{ 'header' => [0, 0], 'data' => { 'banquear' => 0, 'jugar' => 0 } }]
      }
    end

    def usuarios
      render json: UsuariosGenerador.all.order(:correo)
    end

    def save_users
      params[:data].each do |user|
        user2 = UsuariosGenerador.find_or_create_by(id: user['id'])
        user2.correo = user['correo']
        user2.clave = user['clave']
        user2.porcentaje = user['porcentaje']
        user2.can_send = user['can_send']
        user2.save
      end
      params[:deleted].each do |del|
        next if del['id'].blank?

        UsuariosGenerador.find_by(id: del['id']).delete
      end
      render json: { msg: 'OK' }
    end
  end
end


