class SolicitudesController < ApplicationController
skip_before_action :verify_authenticity_token
before_action :check_user_auth, only: [:recargas, :retiros, :ajustar_saldos]
before_action :seguridad_cuentas, only: [:recargas,:retiros]

  def revisar_solicitudes_pendientes
    if session[:usuario_actual]['tipo'] == "COB"
       usuarios = UsuariosTaquilla.where(cobrador_id: session[:usuario_actual]['cobrador_id']).pluck(:id)
       solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: usuarios, status: 1).count
       solicitudes2 = SolicitudRetiro.where(usuarios_taquilla_id: usuarios, status: 1).count
       if (solicitudes + solicitudes2) > 0
         render json: {"hay" => true, "cantidad" => (solicitudes + solicitudes2)}
       else
         render json: {"hay" => false, "cantidad" => 0}
       end
    end

  end



  def verificar_recarga
      @solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: params[:id], status: 1)
      @usuario = UsuariosTaquilla.find(params[:id])
      if @solicitudes.count > 0
      	 # render json: {"msg" => "Todo bien."}
         session[:id_original] = params[:id]
         redirect_to controller: 'solicitudes', action: 'recargas', id: params[:id]
      else
         render json: {"msg" => "El cliente no tiene solicitudes."}, status: 400
      end
  end


  def verificar_retiro
      @solicitudes = SolicitudRetiro.where(usuarios_taquilla_id: params[:id], status: 1)

      @usuario = UsuariosTaquilla.find(params[:id])
      if @solicitudes.count > 0
      	 # render json: {"msg" => "Todo bien."}
         session[:id_original] = params[:id]
         redirect_to controller: 'solicitudes', action: 'retiros', id: params[:id]
      else
         render json: {"msg" => "El cliente no tiene solicitudes."}, status: 400
      end
  end

def recargas
  # if session[:id_original] == params[:id]
    @solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: params[:id], status: 1)
    @usuario = UsuariosTaquilla.find(params[:id])
    render action: 'recargar'
  # else
  #   redirect_to  controller: 'taquillas', action: 'index'
  # end
end




def procesar_recarga
  begin
    ActiveRecord::Base.transaction do
      id_solicitud = params[:id].to_i
      detalle = params[:detalle].to_s
      estado_recarga = params[:status].to_i

      solicitud = SolicitudRecarga.find(id_solicitud)
      if estado_recarga == 2
         # cambio = FactorCambio.find_by(grupo_id: session[:usuario_actual]['grupo_id'], moneda_id: solicitud.cuentas_banca.moneda).valor_dolar
         # moneda_sel = Moneda.find(solicitud.cuentas_banca.moneda).abreviatura
         # monto = (solicitud.monto.to_f / cambio.to_f).round(2)
         actualizar_saldos(solicitud.usuarios_taquilla_id, "Recarga de saldo #{detalle}", solicitud.monto_usd, 2)
      end
      solicitud.update(status: estado_recarga, user_id: session[:usuario_actual]['id'])
      saldo_actual = UsuariosTaquilla.find(solicitud.usuarios_taquilla_id).saldo_usd.to_f
      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_SALDOS_IND", "id" => solicitud.usuarios_taquilla_id.to_i, "monto" => saldo_actual}}

      render json: {"msg" => "Procesado.", "id" => solicitud.usuarios_taquilla_id}
    end
  rescue StandardError => msg
    render json: {"msg" => msg}, status: 400
  end

end


def retiros
  # if session[:id_original] == params[:id]
    @solicitudes = SolicitudRetiro.where(usuarios_taquilla_id: params[:id], status: 1)
    @cuentascliente = CuentasCliente.where(usuarios_taquilla_id: params[:id])
    @usuario = UsuariosTaquilla.find(params[:id])
    render action: 'retirar'
  # else
  #   redirect_to  controller: 'taquillas', action: 'index'
  # end
end

def verificar_tasa
  id = params[:id]
  sol = SolicitudRetiro.find(id)
  moneda_id = sol.cuentas_cliente.moneda
  tasa = sol.tasa.to_f
  monto_cambio = sol.monto_moneda.to_f
  monto_original = sol.monto.to_f
  simbolo = Moneda.find(moneda_id).abreviatura
  render json: {"simbolo" => simbolo, "tasa" => tasa, "monto_original" => monto_original, "monto_cambio" => monto_cambio}

end

def procesar_retiro
  id_solicitud = params[:id].to_i
  detalle = params[:detalle].to_s
  estado_retiro = params[:status].to_i

  solicitud = SolicitudRetiro.find(id_solicitud)
  if estado_retiro == 3
     actualizar_saldos(solicitud.usuarios_taquilla_id, "Retiro rechazado #{detalle}", solicitud.monto , 2)
  end
  solicitud.update(status: estado_retiro, user_id: session[:usuario_actual]['id'])
  render json: {"msg" => "Procesado.", "id" => solicitud.usuarios_taquilla_id}
  #  require 'net/http'
  #  uri = URI('http://127.0.0.1:3003/notificaciones/recarga')
  saldo_actual = UsuariosTaquilla.find(solicitud.usuarios_taquilla_id).saldo_usd.to_f
  ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_SALDOS_IND", "id" => solicitud.usuarios_taquilla_id.to_i, "monto" => saldo_actual}}

  # res = Net::HTTP.post_form(uri, 'usuario_id' => solicitud.usuarios_taquilla_id.to_i, 'grupo_id' => UsuariosTaquilla.find(solicitud.usuarios_taquilla_id.to_i).grupo_id)

end


def ajustar_saldos
  @usuario = UsuariosTaquilla.find(params[:id])
  @type_operation = params[:type].to_i #  1 = Deposito, 2 = Retiro
  if @usuario.present?
     # redirect_to controller: 'solicitudes', action: 'ajustar_saldos', id: params[:id]
     render action: 'ajustar_saldos'
  else
     render json: {"msg" => "El cliente no tiene solicitudes."}, status: 400
  end
end


def ajustar_monto
  if params[:tipo].to_i == 1
     actualizar_saldos(params[:id].to_i, "Deposito ( " + params[:detalle] + " )", params[:monto].to_f, 2)
  else
     actualizar_saldos(params[:id].to_i, "Retiro ( " + params[:detalle] + " )", (params[:monto].to_f * -1), 2)
  end
  type_name = params[:tipo].to_i == 1 ? "Deposito" : "Retiro"
  saldo_actual = 0
  ActiveRecord::Base.transaction do
    MovimientoCajero.create(usuarios_taquilla_id: params[:id].to_i, user_id: session[:usuario_actual]['id'], monto: params[:monto].to_f, 
                            type_operation: type_name, detalle: params[:detalle])
    saldo_actual = UsuariosTaquilla.find(params[:id].to_i).saldo_usd.to_f
  end
  ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_SALDOS_IND", "id" => params[:id].to_i, "monto" => saldo_actual}}
  render json: {"status" => "OK"}
end



def mostrar_imagen
  solicitud = SolicitudRecarga.find(params[:id])
  moneda_id = solicitud.cuentas_banca.moneda
  tasa = solicitud.tasa.to_f
  monto_cambio = solicitud.monto_usd.to_f
  monto_original = solicitud.monto.to_f
  simbolo = Moneda.find(moneda_id).abreviatura
  if solicitud.imagen.url.present?
     render json: {"archivo" => solicitud.imagen.url, "tasa" => tasa, "monto_cambio" => monto_cambio, "monto_original" => monto_original,"simbolo" => simbolo}
  else
    render json: {"archivo" => "", "tasa" => tasa, "monto_cambio" => monto_cambio, "monto_original" => monto_original,"simbolo" => simbolo}, status: 400
  end
end

def get_solicitudes_pendientes
  if session[:usuario_actual]['tipo'] == "GRP"
    usuarios = UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id']).pluck(:id)
  else
    usuarios = UsuariosTaquilla.where(cobrador_id: session[:usuario_actual]['cobrador_id']).pluck(:id)
  end
  @solicitudes = SolicitudRecarga.select("usuarios_taquilla_id, sum(monto) as monto, count(*) as cantidad").where(usuarios_taquilla_id: usuarios, status: 1).group(:usuarios_taquilla_id)
  @solicitudes2 = SolicitudRetiro.select("usuarios_taquilla_id, sum(monto) as monto, count(*) as cantidad").where(usuarios_taquilla_id: usuarios, status: 1).group(:usuarios_taquilla_id)
  render partial: 'cuerpo_solicitudes', layout: false
end

def movimiento_cajero
  @taquillas = UsuariosTaquilla.where(cobrador_id: session[:usuario_actual]['cobrador_id']).order(:nombre)
  @desde = Time.now.strftime('%d/%m/%Y')
  @hasta = Time.now.strftime('%d/%m/%Y')
end

def movimiento_cajero_reporte
  @desde = params[:desde].to_time.beginning_of_day
  @hasta = params[:hasta].to_time.end_of_day

  if params[:taquilla_id].to_i == 0
    @movimientos = MovimientoCajero.where(user_id: session[:usuario_actual]['id'], created_at: @desde..@hasta).order(:created_at)
  else
    @movimientos = MovimientoCajero.where(user_id: session[:usuario_actual]['id'], usuarios_taquilla_id: params[:taquilla_id].to_i, created_at: @desde..@hasta).order(:created_at)
  end

  render partial: 'solicitudes/movimiento_cajero', layout: false
end

private

def actualizar_saldos(usuario_id, descripcion, monto, moneda)
 OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: moneda)
end


end
