  class JornadasController < ApplicationController
    skip_before_action :verify_authenticity_token
    respond_to :json, :html
    before_action :set_jornada, only: [:show, :edit, :update]
    before_action :check_user_auth, only: [:show, :index]
    before_action :seguridad_cuentas, only: [:index,:edit, :new]

    def index
      @jornadas = Jornada.where(fecha: Time.now.beginning_of_day..(Time.now + 5.days)).order(:fecha)
    end

    def show
    end

    def new
      unless session['existe'].present?
        flash.clear
      end
      @jornada = Jornada.new
      @hipodromos = Hipodromo.all.order(:nombre)
      @url = jornadas_path

    end

    def create
      buscar  = Jornada.where(hipodromo_id: params[:jornada]['hipodromo_id'].to_i , fecha: params[:jornada]['fecha'].to_time.all_day)
      if buscar.present?
          @hipodromos = Hipodromo.all.order(:nombre)
          flash[:notice] = 'Ya existe una Jornada para la fecha.'
          session['existe'] = true
          respond_to do |format|
            format.html { redirect_to '/jornadas/new' }
            format.json { head :no_content }
          end
      else
          session['existe'] = false
          @jornada = Jornada.new(jornada_params)
          if @jornada.save
            eval(params.require(:jornada)[:cantidad_carreras]).to_i.times {|tim|
               @jornada.carrera.create(hora_carrera: '', numero_carrera: tim + 1, cantidad_caballos: 0, activo: true )
            }
            @hipodromos = Hipodromo.all.order(:nombre)
            flash[:notice] = 'Jornada creada.'
            respond_to do |format|
              format.html { redirect_to '/jornadas' }
              format.json { head :no_content }
            end
          end
      end
    end

    def edit
      @hipodromos = Hipodromo.all.order(:nombre)
      @hip_act = @jornada.hipodromo_id
      @url = jornada_path(@jornada)
    end

    def update
         carreras_antiores = @jornada.cantidad_carreras.to_i
      if @jornada.update(jornada_params)
        if params[:jornada][:cantidad_carreras].to_i > carreras_antiores
          eval(params.require(:jornada)[:cantidad_carreras]).to_i.times {|tim|
            num_carr = tim + 1
            if num_carr > carreras_antiores
              @jornada.carrera.create(hora_carrera: '', numero_carrera: num_carr, cantidad_caballos: 0, activo: true )
            end
          }
        elsif params[:jornada][:cantidad_carreras].to_i < carreras_antiores
          @jornada.carrera.where(" CAST (numero_carrera AS INTEGER) > #{params[:jornada][:cantidad_carreras].to_i}").destroy_all
        end

        flash[:notice] = 'Jornada actualizado.'
        respond_to do |format|
          format.html { redirect_to '/jornadas' }
          format.json { head :no_content }
        end
      end
    end

    def eliminar_jornada
       jor = Jornada.find_by(id: params[:id])
       if jor.present?
         jor.destroy
       end
       render json: {"status" => "OK"}
      # respond_to do |format|
      #   format.html { redirect_to '/jornadas' }
      #   format.json { head :no_content }
      # end
    end


    private def set_jornada
      @jornada = Jornada.find(params[:id])
    end


    private def jornada_params
      params.require(:jornada).permit(:cantidad_carreras, :hipodromo_id, :fecha)
    end


    end
