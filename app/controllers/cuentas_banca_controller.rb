class CuentasBancaController < ApplicationController
  before_action :set_banco, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index,:edit, :new]

  def index
    case session[:usuario_actual]['tipo']
    when 'GRP'
      @cuentas_bancas = CuentasBanca.where(tipo: 'GRP', grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:banco_id)
    when 'COB'
      @cuentas_bancas = CuentasBanca.where(tipo: 'COB', cobrador_id: session[:usuario_actual]['cobrador_id'].to_i).order(:banco_id)
    else
      @cuentas_bancas = CuentasBanca.where(tipo: 'ADM').order(:banco_id)
    end
  end

  def show
    case session[:usuario_actual]['tipo']
    when 'GRP'
      @cuentas_bancas = CuentasBanca.where(tipo: 'GRP', grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:banco_id)
    when 'COB'
      @cuentas_bancas = CuentasBanca.where(tipo: 'COB', cobrador_id: session[:usuario_actual]['cobrador_id'].to_i).order(:banco_id)
    else
      @cuentas_bancas = CuentasBanca.all.order(:banco_id)
    end
  end

  def new
    case session[:usuario_actual]['tipo']
    when 'GRP'
      @bancos = Banco.where(grupo_id: session[:usuario_actual]['grupo_id'])
    when 'COB'
      @bancos = Banco.where(grupo_id: session[:usuario_actual]['cobrador_id'])
    else
      @bancos = Banco.where(grupo_id: 0)
    end

    @cuentas_banca = CuentasBanca.new
    @url = 'create'
  end

  def create
    @cuentas_banca = CuentasBanca.new(cuentas_banca_params)
   if session[:usuario_actual]['tipo'] == "GRP"
     @cuentas_banca.tipo = "GRP"
     @cuentas_banca.grupo_id = session[:usuario_actual]['grupo_id']
   elsif session[:usuario_actual]['tipo'] == "COB"
     @cuentas_banca.tipo = "COB"
     @cuentas_banca.grupo_id = session[:usuario_actual]['grupo_id']
     @cuentas_banca.cobrador_id = session[:usuario_actual]['cobrador_id']
    else
     @cuentas_banca.tipo = "ADM"
     @cuentas_banca.grupo_id = 0
   end
   if params[:cuentas_banca][:banco_id].to_i == 0
      nuevo = Banco.create(nombre: params[:nombre_banco], moneda: params[:cuentas_banca][:moneda].to_i, grupo_id: @cuentas_banca.grupo_id)
      nuevo.update(banco_id: "BM#{nuevo.id}")
      @cuentas_banca.banco_id = "BM#{nuevo.id}"
   end

    if @cuentas_banca.save
      flash[:notice] = 'Cuenta creada.'
      respond_to do |format|
        format.html { redirect_to '/cuentas_banca'}
        format.json { head :no_content }
      end
    end
  end

  def edit
    @url = cuentas_banca_path(@cuentas_banca)
    if session[:usuario_actual]['tipo'] == "GRP"
      @bancos = Banco.where(grupo_id: session[:usuario_actual]['grupo_id'])
    else
      @bancos = Banco.where(grupo_id: 0)
    end

  end

  def update
    if @cuentas_banca.update(cuentas_banca_params)
      flash[:notice] = 'Cuenta actualizada.'
      respond_to do |format|
        format.html { redirect_to '/cuentas_banca', notice: 'Cuenta modificada.' }
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


  private def set_banco
    @cuentas_banca = CuentasBanca.find(params[:id])
  end


  private def cuentas_banca_params
    params.require(:cuentas_banca).permit(:banco_id, :numero_cuenta, :tipo_cuenta, :nombre_cuenta, :cedula_cuenta, :email_cuenta, :moneda, :detalle, :tipo, :grupo_id, :activa)
  end


end
