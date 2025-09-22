class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_user_auth, only: [:show, :index]

  def getRandomColor
       letters = '0123456789ABCDEF'.split('')
       color = '#'
      6.times{|tim|
        color += letters[rand(9).floor];
      }
      return color
  end


  def index
#     if session["usuario_actual"] == "ADM"
#       todas = []
#       posicion_todas = []
#       todas << ["Element", "Propuestas", { role: "style" } ]
#       Grupo.all.order(:id).each{|grp|
#         propuestas = Propuesta.where(created_at: Time.now.all_day,usuarios_taquilla_id: UsuariosTaquilla.where(grupo_id: grp.id).ids, status: [1,2]).count
#         todas << [grp.nombre, propuestas, getRandomColor()]
#         posicion_todas << [grp.id]
#       }
#       @todas = todas.to_json
#       @posicion_todas = posicion_todas
#       redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
#       cuenta_taq = 0
#       # UsuariosTaquilla.all.each{|usr|
#       #   buscacli = redis.hget("datos_cliente_conectado", usr.id)
#       #   if buscacli.present?
#       #     if JSON.parse(buscacli)["status"] == "On"
#       #        cuenta_taq += 1
#       #     end
#       #   end
#       # }
# #      @total_taquilla = cuenta_taq
# #      @cruzadas = Propuesta.where(status: 2,created_at: Time.now.all_day).count
#       #@cruzadas_bs = Propuesta.where(status: 2,created_at: Time.now.all_day, moneda: 1).count
#       #@cruzadas_usd = Propuesta.where(status: 2,created_at: Time.now.all_day, moneda: 2).count
#  #     @total_propuestas = Propuesta.where(created_at: Time.now.all_day, status: [1,2]).count
#     end
  end



  def actualizar_datos
    todas = []
    posicion_todas = []
    todas << ["Element", "Propuestas", { role: "style" } ]

    Grupo.all.order(:id).each{|grp|
      propuestas = Propuesta.where(created_at: Time.now.all_day,usuarios_taquilla_id: UsuariosTaquilla.where(grupo_id: grp.id).ids, status: [1,2]).count
      todas << [grp.nombre, propuestas, getRandomColor()]
      posicion_todas << [grp.id]
    }
    todas = todas.to_json
    posicion_todas = posicion_todas
    cuenta_taq = 0
    # UsuariosTaquilla.all.each{|usr|
    #   buscacli = redis.hget("datos_cliente_conectado", usr.id)
    #   if buscacli.present?
    #     if JSON.parse(buscacli)["status"] == "On"
    #        cuenta_taq += 1
    #     end
    #   end
    # }
    total_taquilla = cuenta_taq
    cruzadas = Propuesta.where(status: 2,created_at: Time.now.all_day).count
    #cruzadas_bs = Propuesta.where(status: 2,created_at: Time.now.all_day, moneda: 1).count
    #cruzadas_usd = Propuesta.where(status: 2,created_at: Time.now.all_day, moneda: 2).count
    total_propuestas = Propuesta.where(created_at: Time.now.all_day, status: [1,2]).count
     render json: {"status" => "OK", "todas" => todas, "total_taquilla" => total_taquilla, "cruzadas" => cruzadas, "web" => 0, "movil"=> 0, "total_propuestas" => total_propuestas }
  end

end
