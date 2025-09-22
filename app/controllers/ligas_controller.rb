  class LigasController < ApplicationController
    include ApplicationHelper
    skip_before_action :verify_authenticity_token
    respond_to :json, :html
    before_action :set_liga, only: [:show, :edit, :update]
    before_action :check_user_auth, only: [:show, :index]

    before_action :seguridad_cuentas, only: [:index,:edit, :new]
    

      def filtrar
        tipo = params[:id].to_i
        case tipo
        when 0
          @ligas = Liga.all.order(:nombre)
        when 1
          @ligas = Liga.where(activo: true).order(:nombre)
        when 2
          @ligas = Liga.where(activo: false).order(:nombre)
        end
        render partial: 'cuerpo_filtro_liga'
    end


    def index
      @ligas = Liga.all.order(:juego_id)
    end

    def show
    end

    def new
      unless session['existe'].present?
        flash.clear
      end
      @liga = Liga.new
      @url = ligas_path
    end

    def create
       buscar  = Liga.where(liga_id: params[:liga]['liga_id'].to_i)
      if buscar.present?
          flash[:notice] = 'Ya existe una Liga con ese nombre.'
          session['existe'] = true
          respond_to do |format|
            format.html { redirect_to '/ligas/new' }
            format.json { head :no_content }
          end
      else
          session['existe'] = false
          @liga = Liga.new(liga_params)
          if params[:radio_activo].present?
             @liga.activo = true
           else
             @liga.activo = false
          end
          @liga.save
            flash[:notice] = 'Liga creada.'
            respond_to do |format|
              format.html { redirect_to '/ligas' }
              format.json { head :no_content }
            end
      end
    end

    def edit
      @liga = Liga.find(params[:id])
      @url = liga_path(@liga)
    end

    def update
        @liga.update(liga_params)
        if params[:radio_activo].present?
           @liga.update(activo: true)
         else
           @liga.update(activo: false)
        end
        ActionCable.server.broadcast "publicas_deporte_channel", { data: {"tipo" => "UPDATE_LIGA", "data_menu" => menu_deportes_helper(@liga.juego_id), "deporte_id" => @liga.juego_id, "liga_id" => @liga.liga_id }}

        flash[:notice] = 'Liga actualizada.'
        respond_to do |format|
          format.html { redirect_to '/ligas' }
          format.json { head :no_content }
        end
    end

    def destroy
       jue = Liga.find_by(id: params[:id])
       if jue.present?
         jue.destroy
       end
      respond_to do |format|
        format.html { redirect_to '/ligas' }
        format.json { head :no_content }
      end
    end


    private def set_liga
      @liga = Liga.find(params[:id])
    end


    private
    def liga_params
      params.require(:liga).permit(:juego_id, :liga_id, :nombre)
    end

end
