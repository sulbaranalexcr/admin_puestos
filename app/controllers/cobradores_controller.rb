class CobradoresController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cobradores, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index,:edit, :new]


  def index
    @cobradores = Cobradore.where(grupo_id: session[:usuario_actual]['grupo_id']).order(:nombre)
    @integradores = Integrador.where(grupo_id: session[:usuario_actual]["grupo_id"])  end

  def show
  end

  def new
    @cobradore = Cobradore.new
    @url = cobradores_path
    @integradores = Integrador.where(grupo_id: session[:usuario_actual]["grupo_id"])
  end

  def create
    @cobradore = Cobradore.new(cobradore_params)
    if @cobradore.save
      Estructura.create(nombre: params[:cobradore][:nombre] + " " + params[:cobradore][:apellido],representante: "", telefono: params[:cobradore][:telefono], correo: params[:cobradore][:correo], tipo: 5, tipo_id: @cobradore.id, padre_id: session[:usuario_actual]['grupo_id'], activo: params[:cobradore][:activo])
      FactorCambio.create(moneda_id: params[:cobradore][:moneda_id], grupo_id: session[:usuario_actual]["grupo_id"], valor_dolar: 1, cobrador_id: @cobradore.id )
      flash[:notice] = 'Cobrador creado.'
      respond_to do |format|
        format.html { redirect_to '/agentes/' + @cobradore.id.to_s + '/edit' }
        format.json { head :no_content }
      end
    else
      puts @cobradore.errors.messages
    end
  end

  def edit
    @taquis_otros = []
    @taquis_propias = []
    @integradores = Integrador.where(grupo_id: session[:usuario_actual]['grupo_id'])
    @cobradore = Cobradore.find(params[:id])
    if @cobradore.usuarios_taquilla_id.present?
      @taquis_propias = JSON.parse(@cobradore.usuarios_taquilla_id)
    end
    @todas_taq = @taquis_propias
    @taquillas = UsuariosTaquilla.where("grupo_id = #{session[:usuario_actual]['grupo_id']} and cobrador_id = #{params[:id]} or grupo_id = #{session[:usuario_actual]['grupo_id']} and cobrador_id = 0").order(:alias)
    @url = cobradore_path(@cobradore)
  end

  def update
    if @cobradore.update(cobradore_params)
      @cobradore.update(deporte_id: params[:cobradore][:deporte_id].to_json)
      Estructura.where(tipo: 5, tipo_id: @cobradore.id).update(nombre: params[:cobradore][:nombre] + " " + params[:cobradore][:apellido], telefono: params[:cobradore][:telefono], correo: params[:cobradore][:correo], activo: params[:cobradore][:activo])
      busca_tasa = FactorCambio.find_by(grupo_id: session[:usuario_actual]['grupo_id'], cobrador_id: @cobradore.id)

      if busca_tasa.present?
        busca_tasa.update(moneda_id: params[:cobradore][:moneda_id])
      else
        FactorCambio.create(moneda_id: params[:cobradore][:moneda_id], grupo_id: session[:usuario_actual]['grupo_id'],
                            valor_dolar: 1.0, cobrador_id: @cobradore.id)
      end
      UsuariosTaquilla.where(cobrador_id: @cobradore.id).update(moneda_default: params[:cobradore][:moneda_id])
      taq_selec = []
      if params[:taquillas].present?
        params[:taquillas].each do |taq, _index|
          taq_selec << taq.to_i
        end
      end
      @cobradore.update(usuarios_taquilla_id: taq_selec.to_json)
      buscar_factor = FactorCambio.where(cobrador_id: @cobradore.id).last
      UsuariosTaquilla.where(cobrador_id: @cobradore.id).update_all(cobrador_id: 0, updated_at: DateTime.now)
      if taq_selec.length.positive?
        UsuariosTaquilla.where(id: taq_selec)
                        .update_all(cobrador_id: @cobradore.id, moneda_default: buscar_factor.moneda_id, simbolo_moneda_default: buscar_factor.moneda[0], moneda_default_dolar: buscar_factor.valor_dolar, updated_at: DateTime.now)
      end

      unless @cobradore.activo
        ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'BLOQUEAR_TAQUILLA', 'taq_id' => 0, 'grupo_id' => 0, 'cobrador_id' => @cobradore.id }}
      end

      flash[:notice] = 'Cobradore actualizado.'
      respond_to do |format|
        format.html { redirect_to '/agentes' }
        format.json { head :no_content }
      end
    end
  end

  private

  def set_cobradores
    @cobradore = Cobradore.find(params[:id])
  end

  def cobradore_params
    grupo_default = { grupo_id: session[:usuario_actual]['grupo_id'] }
    params.require(:cobradore).permit(:nombre, :apellido, :telefono, :correo, :vende_ganadores, :activo, :integrador_id,:comision_banca, :comision_grupo,:comision_integrador, :moneda_id, :cobrador_id).reverse_merge(grupo_default)
  end

end
