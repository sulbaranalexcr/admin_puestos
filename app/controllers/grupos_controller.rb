class GruposController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_grupo, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index,:edit, :new]

  def index
    if session[:usuario_actual]['tipo'] == "ADM"
      @grupos = Grupo.all.order(:nombre)
    else
      @grupos = Grupo.where(intermediario_id: session[:usuario_actual]['intermediario_id'] ).order(:nombre)
    end
  end

  def show; end

  def new
    @grupo = Grupo.new
    @url = grupos_path
  end

  def create
    @grupo = Grupo.new(grupo_params)
    if @grupo.save
      Estructura.create(nombre: params[:grupo][:nombre],representante: params[:grupo][:representante], telefono: params[:grupo][:telefono], correo: params[:grupo][:correo], tipo: 3, tipo_id: @grupo.id, padre_id: 0, activo: params[:grupo][:activo])
      flash[:notice] = 'Grupo creado.'
      respond_to do |format|
        format.html { redirect_to '/grupos' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @grupo = Grupo.find(params[:id])
    @url = grupo_path(@grupo)
  end

  def update
    if @grupo.update(grupo_params)
      Estructura.where(tipo: 3, tipo_id: @grupo.id).update(nombre: params[:grupo][:nombre],representante: params[:grupo][:representante], telefono: params[:grupo][:telefono], correo: params[:grupo][:correo], activo: params[:grupo][:activo])
      unless params[:activo]
        ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "BLOQUEAR_TAQUILLA", "taq_id" => 0, "grupo_id" => params[:id].to_i, "cobrador_id" => 0 } }
      end
      flash[:notice] = 'Grupo actualizado.'
      respond_to do |format|
        format.html { redirect_to '/grupos' }
        format.json { head :no_content }
      end
    end

  end

  # def destroy
  #   @jornada.destroy
  #   respond_to do |format|
  #     format.html { redirect_to '/jornadas' }
  #     format.json { head :no_content }
  #   end
  # end


  private def set_grupo
    @grupo = Grupo.find(params[:id])
  end


  private def grupo_params
    params.require(:grupo).permit(:nombre, :representante, :telefono, :correo, :porcentaje_banca,:porcentaje_taquilla, :activo,:intermediario_id,:porcentaje_intermediario)
  end




end
