class TasasCambioController < ApplicationController
  before_action :set_factor, only: %i[edit update destroy]
  skip_before_action :verify_authenticity_token
  before_action :check_user_auth, only: %i[show index]
  before_action :seguridad_cuentas, only: %i[index edit new]

  def index
    if params[:tipo].present? && params[:tipo] == '2'
      @tipo = params[:tipo]
      @monedas = Moneda.where(id: FactorCambio.where.not(moneda_id: 2).where(grupo_id: session[:usuario_actual]['grupo_id'].to_i, ).group(:moneda_id).pluck(:moneda_id))
      render action: 'por_moneda'
    else
      @tipo = '1'
      @factor = FactorCambio.where.not(moneda_id: 2).where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:id)
    end
  end

  def show
    id = params[:format].to_i
    @moneda = Moneda.find(id)
    grupo_id = session[:usuario_actual]['grupo_id'].to_i
    buscar = HistorialTasaGrupo.where(grupo_id: grupo_id, moneda_id: id).last
    @valor_anterior = 0
    @valor_anterior = buscar.nueva_tasa.to_f if buscar.present?
    @url = '/tasas_cambio/update_grupo'
  end

  def new
    @monedas = Moneda.all
    @factor = FactorCambio.new
    @agentes = Cobradore.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i)
    @url = 'create'
  end

  def create
    obtenet_data = request.location.data()
    buscar = FactorCambio.new(moneda_id: params[:moneda], grupo_id: session[:usuario_actual]['grupo_id'].to_i,cobrador_id: params[:agentes].to_i)
    if buscar.present?
      flash[:notice] = 'Tasa Ya existe para este agente.'
      respond_to do |format|
        format.html { redirect_to '/tasas_cambio'}
      end
      return
    end

    @factor = FactorCambio.new(moneda_id: params[:moneda], valor_dolar: params[:tasa], grupo_id: session[:usuario_actual]['grupo_id'].to_i,cobrador_id: params[:agentes].to_i)

    return unless @factor.save

    HistorialTasa.create(user_id: session[:usuario_actual]['id'].to_i, moneda_id: params[:moneda], tasa_anterior: 0, tasa_nueva: params[:tasa], ip_remota: request.remote_ip, grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]["cobrador_id"].to_i, geo: obtenet_data.to_json)
    HistorialTasaGrupo.create(user_id: session[:usuario_actual]['id'].to_i,grupo_id: session[:usuario_actual]['grupo_id'].to_i, moneda_id: params[:moneda], tasa_anterior: 0, nueva_tasa: params[:tasa])
    flash[:notice] = 'Tasa creada.'
    respond_to do |format|
      format.html { redirect_to '/tasas_cambio' }
      format.json { head :no_content }
    end
  end

  def edit
    @monedas = Moneda.where.not(id: 2)
    @factor = FactorCambio.find(params[:id])
    @url = tasas_cambio_path(@factor)
  end

  def por_agentes
    id = params[:id_moneda].to_i
    valor = params[:valor_moneda]
    grupo_id = session[:usuario_actual]['grupo_id'].to_i
    factor = FactorCambio.where(grupo_id: grupo_id, moneda_id: id)
    return unless factor.present?

    factor.update(valor_dolar: valor)
    UsuariosTaquilla.where(grupo_id: grupo_id, moneda_default: id).update(moneda_default_dolar: valor)
    buscar = HistorialTasaGrupo.where(grupo_id: grupo_id, moneda_id: id)
    valor_anterior = 0
    valor_anterior = buscar.last.nueva_tasa.to_f if buscar.present?
    HistorialTasaGrupo.create(user_id: session[:usuario_actual]['id'].to_i, moneda_id: id, tasa_anterior: valor_anterior.to_f, nueva_tasa: valor, grupo_id: session[:usuario_actual]['grupo_id'].to_i)
  end

  def update
    obtenet_data = request.location.data

    valor_anterior = @factor.valor_dolar.to_f
    return unless @factor.update(moneda_id: params[:moneda], valor_dolar: params[:tasa])

    agente_id = @factor.cobrador_id
    UsuariosTaquilla.where(cobrador_id: agente_id).update_all(moneda_default: params[:moneda], moneda_default_dolar: params[:tasa], simbolo_moneda_default: Moneda.find(params[:moneda]).abreviatura,updated_at: DateTime.now)
    HistorialTasa.create(user_id: session[:usuario_actual]['id'].to_i, moneda_id: params[:moneda], tasa_anterior: valor_anterior.to_f, tasa_nueva: params[:tasa], ip_remota: request.remote_ip, grupo_id: session[:usuario_actual]['grupo_id'].to_i, cobrador_id: session[:usuario_actual]["cobrador_id"].to_i, geo: obtenet_data.to_json)
    HistorialTasaGrupo.create(user_id: session[:usuario_actual]['id'].to_i,grupo_id: session[:usuario_actual]['grupo_id'].to_i, moneda_id: params[:moneda], tasa_anterior: valor_anterior.to_f, nueva_tasa: params[:tasa])
    flash[:notice] = 'Tasa actualizada.'
    respond_to do |format|
      format.html { redirect_to '/tasas_cambio', notice: 'Tasa modificada.' }
      format.json { head :no_content }
    end
  end

  def destroy
    @cuentas_banca.destroy
    respond_to do |format|
      format.html { redirect_to '/cuentas_banca' }
      format.json { head :no_content }
    end
  end

  private

  def set_factor
    @factor = FactorCambio.find(params[:id])
  end
end
