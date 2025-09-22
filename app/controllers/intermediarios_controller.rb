class IntermediariosController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_intermediario, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index,:edit, :new]


  def index
    @intermediarios = Intermediario.all.order(:nombre)
  end

  def show
  end

  def new
    @intermediario = Intermediario.new
    @url = intermediarios_path

  end

  def create

    @intermediario = Intermediario.new(intermediario_params)
    if @intermediario.save
      Estructura.create(nombre: params[:intermediario][:nombre],representante: params[:intermediario][:representante], telefono: params[:intermediario][:telefono], correo: params[:intermediario][:correo], tipo: 2, tipo_id: @intermediario.id, padre_id: 0, activo: params[:intermediario][:activo])
      flash[:notice] = 'Intermediario creado.'
      respond_to do |format|
        format.html { redirect_to '/intermediarios' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @intermediario = Intermediario.find(params[:id])
    @url = intermediario_path(@intermediario)
  end

  def update
    if @intermediario.update(intermediario_params)
      Estructura.where(tipo: 2, tipo_id: @intermediario.id).update(nombre: params[:intermediario][:nombre],representante: params[:intermediario][:representante], telefono: params[:intermediario][:telefono], correo: params[:intermediario][:correo], activo: params[:intermediario][:activo])
      flash[:notice] = 'Intermediario actualizado.'
      respond_to do |format|
        format.html { redirect_to '/intermediarios' }
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


  private def set_intermediario
    @intermediario = Intermediario.find(params[:id])
  end


  private def intermediario_params
    params.require(:intermediario).permit(:nombre, :representante, :telefono, :correo, :porcentaje_banca,:porcentaje_taquilla, :activo,:intermediario_id,:porcentaje_intermediario,:direccion)
  end




end
