class FactorCambioController < ApplicationController
    before_action :set_factor, only: [:edit, :update, :destroy]
    skip_before_action :verify_authenticity_token
    before_action :check_user_auth, only: [:show, :index]
    before_action :seguridad_cuentas, only: [:index,:edit, :new]

  def index
     @factor = FactorCambio.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]['cobrador_id'].to_i).order(:id)
  end

  def consulta
    @factor = FactorCambio.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]['cobrador_id'].to_i).order(:id)
  end

  def show
    @factor = FactorCambio.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]['cobrador_id'].to_i).order(:id)
  end

  def new
    @monedas = Moneda.all
    @factor = FactorCambio.new
    @url = 'create'
  end

  def create
    obtenet_data = request.location.data()
    @factor = FactorCambio.new(moneda_id: params[:moneda], valor_dolar: params[:tasa], grupo_id: session[:usuario_actual]['grupo_id'].to_i,cobrador_id: session[:usuario_actual]['cobrador_id'].to_i)
    if @factor.save
      HistorialTasa.create(user_id: session[:usuario_actual]['id'].to_i, moneda_id: params[:moneda], tasa_anterior: 0, tasa_nueva: params[:tasa], ip_remota: request.remote_ip, grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]["cobrador_id"].to_i, geo: obtenet_data.to_json)
      flash[:notice] = 'Tasa creada.'
      respond_to do |format|
        format.html { redirect_to '/factor_cambio'}
        format.json { head :no_content }
      end
    end
  end

  def edit
    @monedas = Moneda.all
    @url = factor_cambio_path(@factor)
  end

  def update
    obtenet_data = request.location.data()

    valor_anterior = @factor.valor_dolar.to_f
    if @factor.update(moneda_id: params[:moneda], valor_dolar: params[:tasa])
       agente_id = @factor.cobrador_id
       UsuariosTaquilla.where(cobrador_id: agente_id).update_all(moneda_default_dolar: params[:tasa], updated_at: DateTime.now)
       HistorialTasa.create(user_id: session[:usuario_actual]['id'].to_i, moneda_id: params[:moneda], tasa_anterior: valor_anterior.to_f, tasa_nueva: params[:tasa], ip_remota: request.remote_ip, grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]["cobrador_id"].to_i, geo: obtenet_data.to_json)
       flash[:notice] = 'Tasa actualizada.'
       respond_to do |format|
         format.html { redirect_to '/factor_cambio', notice: 'Tasa modificada.' }
         format.json { head :no_content }
       end
    end
  end

  def destroy
    @cuentas_banca.destroy
    respond_to do |format|
      format.html { redirect_to '/cuentas_banca' }
      format.json { head :no_content }
    end
  end



  private def set_factor
    @factor = FactorCambio.find(params[:id])
  end




  end
