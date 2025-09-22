class HipodromosController < ApplicationController
  # respond_to :json, :html
  skip_before_action :verify_authenticity_token
  before_action :set_hipodromo, only: %i[show edit update destroy]
  before_action :check_user_auth, only: %i[show index]

  before_action :seguridad_cuentas, only: %i[index new edit]

  def index
    @hipodromos = Hipodromo.all.order(:pais, :nombre)
  end

  def show
    @hipodromos = Hipodromo.all.order(:nombre)
  end

  def filtrar
    tipo = params[:id].to_i
    case tipo
    when 0
      @hipodromos = Hipodromo.all.order(:nombre)
    when 1
      @hipodromos = Hipodromo.where(activo: true).order(:nombre)
    when 2
      @hipodromos = Hipodromo.where(activo: false).order(:nombre)
    when 3
      @hipodromos = Hipodromo.where(activo: false).where("length(codigo_nyra) > 0").order(:nombre)
    end
    render partial: 'cuerpo_filtro'
  end

  def new
    @hipodromo = Hipodromo.new
    @url = hipodromos_path
  end

  def create
    @hipodromo = Hipodromo.new(hipodromo_params)

    if @hipodromo.save
      flash[:notice] = 'Hipodromo creado.'
      respond_to do |format|
        format.html { redirect_to '/hipodromos' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @url = hipodromo_path(@hipodromo)
  end

  def update
    if @hipodromo.update(hipodromo_params)
      flash[:notice] = 'Hipodromo actualizado.'
      respond_to do |format|
        format.html { redirect_to '/hipodromos' }
        format.json { head :no_content }
      end
    end
  end

  def destroy
    @hipodromo.destroy
    respond_to do |format|
      format.html { redirect_to '/hipodromos' }
      format.json { head :no_content }
    end
  end

  def cierre_api
    @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id), activo: true)
  end

  def update_cierres
    data = params[:data]
    data.each do |hip|
      Hipodromo.find(hip['id']).update(cierre_api: hip['cierre'])
    end
    render json: { msg: 'OK' }
  end

  private

  def set_hipodromo
    @hipodromo = Hipodromo.find(params[:id])
  end

  def hipodromo_params
    params.require(:hipodromo).permit(:nombre, :nombre_largo, :tipo, :cantidad_puestos, :activo, :cierre_api,
                                      :codigo_nyra)
  end
end
