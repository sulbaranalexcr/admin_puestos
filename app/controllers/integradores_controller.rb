class IntegradoresController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_integradores, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index,:edit, :new]

  def index
    @integradores = Integrador.all.order(:nombre)
  end

  def show
  end

  def new
    @integrador = Integrador.new
    @url = '/integradores'
  end

  def generar_token
    nuevo = SecureRandom.urlsafe_base64(64)
    bus_to = Integrador.find_by(api_key: nuevo)
    if bus_to.present?
      generar_token
    else
      nuevo
    end
  end

  def create
    @integrador = Integrador.new(integrador_params)
    @integrador.api_key = generar_token
    if @integrador.save
      @integrador.create_datos_cajero_integrador(datos_cajero: default_data_integrator.to_json)
      flash[:notice] = 'Integrador creado.'
      respond_to do |format|
        format.html { redirect_to '/integradores' }
        format.json { head :no_content }
      end
    else
      puts @integrador.errors.messages
    end
  end

  def edit
    @integrador = Integrador.find(params[:id])
    @url = "/integradores/#{params[:id]}"
  end

  def update
    datos = JSON.parse(@integrador.datos_cajero_integrador.datos_cajero)

    datos['obtener_saldo'] = convert_data(JSON.parse(params[:balance].to_json))
    datos['debitar_saldo'] = convert_data(JSON.parse(params[:withdraw].to_json))
    datos['acreditar_saldo'] = convert_data(JSON.parse(params[:deposit].to_json))
    datos['acreditar_saldo_bloque'] = convert_data(JSON.parse(params[:deposit_block].to_json))

    @integrador.datos_cajero_integrador.update(datos_cajero: datos.to_json)
    if @integrador.update(integrador_params)
      flash[:notice] = 'Integrador actualizado.'
      respond_to do |format|
        format.html { redirect_to '/integradores' }
        format.json { head :no_content }
      end
    end
  end

  private

  def convert_data(string_data)
    {
      'metodo' => string_data['metodo'],
      'url' => string_data['url'],
      'parametros_header' => JSON.parse(string_data['parametros_header'].gsub('=>', ':')),
      'parametros_body' => JSON.parse(string_data['parametros_body'].gsub('=>', ':')),
      'retorno' => JSON.parse(string_data['retorno'].gsub('=>', ':'))
    }
  end

  def set_integradores
    @integrador = Integrador.find(params[:id])
  end

  def integrador_params
    params.require(:integrador).permit(:nombre, :representante, :telefono, :grupo_id, :activo, :usa_cajero_externo)
  end

  def default_date_cajero
    {
      obtener_saldo: { metodo: '', url: '', parametros_header: [], parametros_body: [], retorno: '' },
      debitar_saldo: { metodo: '', url: '', parametros_header: [], parametros_body: [], retorno: '' },
      acreditar_saldo: { metodo: '', url: '', parametros_header: [], parametros_body: [], retorno: '' },
      acreditar_saldo_bloque: { metodo: '', url: '', parametros_header: [], parametros_body: [], retorno: '' }
    }
  end
end
