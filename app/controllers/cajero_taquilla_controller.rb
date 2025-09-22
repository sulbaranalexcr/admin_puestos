class CajeroTaquillaController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_taquilla, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index, :edit, :new]

  def index
    @taquillas = UsuariosTaquilla.where(cobrador_id: session[:usuario_actual]["cobrador_id"]).order(:nombre)
  end

  def verificar_recarga
    @solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: params[:id])
    @usuario = UsuariosTaquilla.find(params[:id])
    if @solicitudes.count > 0
      # render json: {"msg" => "Todo bien."}
      redirect_to controller: "thing", action: "edit", id: 3, something: "else"
    else
      render json: { "msg" => "El cliente no tiene solicitudes." }, status: 400
    end
  end

  private
  def set_taquilla
    @taquilla = UsuariosTaquilla.find(params[:id])
  end

  def taquilla_params
    params.require(:usuarios_taquilla).permit(:nombre, :cedula, :alias, :telefono, :correo, :activo, :grupo_id, :comision, :clave, :jugada_minima_bs, :jugada_maxima_bs, :jugada_minima_usd, :jugada_maxima_usd, :propone, :toma, :usa_cajero_externo, :cobrador_id, :demo)
  end

  def taquilla_params2
    params.require(:usuarios_taquilla).permit(:nombre, :cedula, :alias, :telefono, :correo, :activo, :grupo_id, :comision, :jugada_minima_bs, :jugada_maxima_bs, :jugada_minima_usd, :jugada_maxima_usd, :propone, :toma, :usa_cajero_externo, :cobrador_id, :demo)
  end

  # UsuariosTaquilla.all.each{|taq|
  #   buscar = Estructura.find_by(tipo: 4, tipo_id: taq.id)
  #   unless buscar.present?
  #     Estructura.create(nombre: taq.alias, representante: taq.grupo.nombre, telefono: taq.telefono, correo: taq.correo, rif: taq.cedula, tipo: 4, tipo_id: taq.id, padre_id: taq.grupo.estructura_id, activo: true)
  #   end
  # }

end
