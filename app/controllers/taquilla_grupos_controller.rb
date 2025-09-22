class TaquillaGruposController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_taquilla, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]

  def index
    @taquillas =  UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id']).order(:nombre)

  end

  def show
  end

  def new
    @taquilla = UsuariosTaquilla.new
    @url = taquilla_grupos_path(@taquilla)
  end



  def create

    @taquilla = UsuariosTaquilla.new(taquilla_params)
    clave = @taquilla.clave
    @taquilla.clave = Digest::MD5.hexdigest(clave)
    if @taquilla.save
      flash[:notice] = 'UsuariosTaquilla creado.'
      respond_to do |format|
        format.html { redirect_to '/taquillas_grupo' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @taquilla = UsuariosTaquilla.find(params[:id])
    @url = taquilla_grupos_path(@taquilla)
  end

  def update
    if @taquilla.update(taquilla_params)
       clave = @taquilla.clave
       @taquilla.update(clave: Digest::MD5.hexdigest(clave))
      unless params[:activo]
        begin
          require 'net/http'
          uri = URI('http://127.0.0.1:3003/login/desloguear_taquilla')
          res = Net::HTTP.post_form(uri, 'taq_id' => params[:id].to_i, 'grupo_id' => 0)
        rescue
        end
      end
      flash[:notice] = 'Taquilla actualizada.'
      respond_to do |format|
        format.html { redirect_to '/taquilla_grupos' }
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

  def buscar_por_grupo
      id = params[:id].to_i
      @taquillas = UsuariosTaquilla.where(grupo_id: id).order(:nombre)
      render partial: 'taquillas/cuerpo',  layout: false
  end


  private def set_taquilla
    @taquilla = UsuariosTaquilla.find(params[:id])
  end


  private def taquilla_params
    params.require(:usuarios_taquilla).permit(:nombre, :alias, :telefono, :correo, :activo, :grupo_id, :comision, :clave, :jugada_minima_bs, :jugada_maxima_bs, :jugada_minima_usd, :jugada_maxima_usd)
  end




end
