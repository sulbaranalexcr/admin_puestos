  class EquiposController < ApplicationController
    respond_to :json, :html
    before_action :set_equipo, only: [:show, :edit, :update]
    before_action :check_user_auth, only: [:show, :index]
    skip_before_action :verify_authenticity_token
    before_action :seguridad_cuentas, only: [:index,:edit, :new]

    def index
      @equipos = Equipo.all.order(:equipo_id)
    end

    def show
    end

    def new
      unless session['existe'].present?
        flash.clear
      end
      @equipo = Equipo.new
      @url = equipos_path
    end

    def create
       buscar  = Equipo.where(equipo_id: params[:equipo]['equipo_id'].to_i)
      if buscar.present?
          flash[:notice] = 'Ya existe un Equipo con ese nombre.'
          session['existe'] = true
          respond_to do |format|
            format.html { redirect_to '/equipos/new' }
            format.json { head :no_content }
          end
      else
          session['existe'] = false
          @equipo = Equipo.new(equipo_params)
          @equipo.save
            flash[:notice] = 'Equipo creado.'
            respond_to do |format|
              format.html { redirect_to '/equipos' }
              format.json { head :no_content }
            end
      end
    end

    def edit
      @equipo = Equipo.find(params[:id])
      @deporte = Juego.find_by(juego_id: Liga.find_by(liga_id: @equipo.liga_id).juego_id)
      @url = equipo_path(@equipo)
    end

    def update
        @equipo.update(equipo_params)
        flash[:notice] = 'Equipo actualizado.'
        respond_to do |format|
          format.html { redirect_to '/equipos' }
          format.json { head :no_content }
        end
    end

    def destroy
       jue = Equipo.find_by(id: params[:id])
       if jue.present?
         jue.destroy
       end
      respond_to do |format|
        format.html { redirect_to '/equipos' }
        format.json { head :no_content }
      end
    end


   def buscar_liga
     @ligas = Liga.where(juego_id: params[:id], activo: true)
     render partial: 'equipos/ligas',  layout: false
   end

    private def set_equipo
      @equipo = Equipo.find(params[:id])
    end


    private
    def equipo_params
      params.require(:equipo).permit(:equipo_id,:liga_id,:nombre, :nombre_largo)
    end

end
