class JuegosController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :json, :html
  before_action :set_juego, only: %i[show edit update]
  before_action :check_user_auth, only: %i[show index]
  before_action :seguridad_cuentas, only: %i[index edit new]

  def index
    @juegos = Juego.all.order(:juego_id)
  end

  def show; end

  def new
    flash.clear unless session['existe'].present?
    @juego = Juego.new
    @url = juegos_path
  end

  def create
    buscar = Juego.where(juego_id: params[:juego]['juego_id'].to_i)
    if buscar.present?
      flash[:notice] = 'Ya existe una Juego con ese nombre.'
      session['existe'] = true
      respond_to do |format|
        format.html { redirect_to '/juegos/new' }
        format.json { head :no_content }
      end
    else
      session['existe'] = false
      @juego = Juego.new(juego_params)
      @juego.save
      flash[:notice] = 'Juego creado.'
      respond_to do |format|
        format.html { redirect_to '/juegos' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @juego = Juego.find(params[:id])
    @url = juego_path(@juego)
  end

  def update
    @juego.update(juego_params)
    flash[:notice] = 'Juego actualizado.'
    respond_to do |format|
      format.html { redirect_to '/juegos' }
      format.json { head :no_content }
    end
  end

  def destroy
    jue = Juego.find_by(id: params[:id])
    jue.destroy if jue.present?
    respond_to do |format|
      format.html { redirect_to '/juegos' }
      format.json { head :no_content }
    end
  end

  private def set_juego
    @juego = Juego.find(params[:id])
  end

  private

  def juego_params
    params.require(:juego).permit(:juego_id, :nombre, :imagen)
  end
end
