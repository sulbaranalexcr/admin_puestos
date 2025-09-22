class TablasController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :json, :html
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index]


  # before_action :set_carrera, only: [:show, :edit, :update, :destroy]

  def index
    @hipodromos = Hipodromo.where(id: Jornada.where(fecha: Time.now.all_day).pluck(:hipodromo_id)).order(:nombre_largo)
  end

  def buscar_carreras
    carreras = Carrera.where(jornada_id: Jornada.where(hipodromo_id: params[:id]).last.id, activo: true).order(:id)
    carreras_existemtes = TablasFija.where(hipodromo_id: params[:id], created_at: Time.now.all_day).pluck(:carrera_id) 
    if carreras.present?
    carreras_final = carreras.each{|carr|
        if carreras_existemtes.include?(carr.id)
          carr.ingresada = true
        else 
          carr.ingresada = false
        end
      }
      render json: {"carreras" => carreras_final }, methods: [:ingresada]
    else
      render json: {"status" => "FAILD"}, status: 400
    end
  end
  
  def crear_caballos
    carrera_id = params[:id].to_i
    ingresados = []   
    @data = {}.to_json
    @existe =  0
    @carrera_hora = Carrera.find(carrera_id).hora_pautada
    carrera = Carrera.find(params[:id])
    abreviatura = carrera.jornada.hipodromo.abreviatura
    tablas_dinamica = TablasDinamica.where(carrera_id: params[:id]).last
    caballos_object = []
    @add = false 
      
    caballos = CaballosCarrera.where(carrera_id: params[:id]).order(Arel.sql("to_number(numero_puesto,'99')"))
    @caballos_array = []
    @cantidad_valido = 0
    if caballos.present?
      if tablas_dinamica.present?
        @add = true
        tablas_dinamica.tablas_detalles.each do |td|
          caballos_object << td
        end
      end
      caballos.each do |ca|
        search_horse = caballos_object.find { |a| a.caballos_carrera_id == ca.id }
        @caballos_array << {"id" => ca.id,"numero_puesto" => ca.numero_puesto, "nombre" => ca.nombre, "retirado" => ca.retirado, "ventas" => 0, "riesgo" => 0, "div" => 0, "disp" => 0, "valor" => find_valor(search_horse, 'valor'), "ctablas" => find_valor(search_horse, 'cantidad_tablas') }
        unless ca.retirado
          @cantidad_valido += 1
        end
      end
    end
    render json: { "caballos" => @caballos_array, "add" => @add, "status" => tablas_dinamica.present? ? tablas_dinamica.status : 'not_found' }
      # render partial: 'tablas/caballos',  layout: false
  end
  
  def find_valor(search_horse, type)
    return 0 unless search_horse.present?

    case type
    when 'valor'
      search_horse['valor']
    else
      search_horse['cantidad_tablas']
    end
  end

  
  def procesar_carga
    carrera_id = params[:carrera_id].to_i
    jornada_id = carrera.jornada_id
    hipodromo_id = carrera.jornada.hipodromo_id 
    render json: { status: "Error", message: 'Tabla ya existe.' }, status: 400 and return if exist_table
    ActiveRecord::Base.transaction do
      new_tabla = TablasDinamica.create(carrera_id: carrera_id, jornada_id: jornada_id, hipodromo_id: hipodromo_id, monto_pagar: params[:monto_tabla].to_f, status: 0)
      new_tabla.tablas_detalles.create(params_horses)
    end 
    render json: { status: "OK" }
  end

  def exist_table
    TablasDinamica.where(carrera_id: params[:carrera_id]).present?
  end
  def carrera
    @carrera ||= Carrera.find(params[:carrera_id])
  end

  private
  def params_horses
    params.require(:caballos).map do |cab| 
      { 
        caballos_carrera_id: cab[:id], 
        retirado: cab[:retirado], 
        valor: cab[:valor], 
        cantidad_tablas: cab[:ctablas] 
      }
    end
  end
  # def procesar_carga 
  #   begin
  #     if params[:tipo_graba].to_i == 0
  #       nuevo = TablasFija.create(hipodromo_id: params[:hipodromo], carrera_id: params[:carrera], premio: params[:premio], disponible: params[:disponibilidad], comision: params[:comision], activo: true)
  #       caballos = params[:caballos]
  #       caballos.each{|cab|
  #         if cab['monto'].to_f > 0 
  #           TablasFijasDetalle.create(tablas_fija_id: nuevo.id, caballo_id: cab['id'], costo: cab['monto'], status: 1, activo: true)
  #         else 
  #           TablasFijasDetalle.create(tablas_fija_id: nuevo.id, caballo_id: cab['id'], costo: cab['monto'], status: 2, activo: false)        
  #         end
  #       }
  #     else 
  #       nuevo = TablasFija.find_by(hipodromo_id: params[:hipodromo], carrera_id: params[:carrera])
  #       nuevo.update(premio: params[:premio], disponible: params[:disponibilidad], comision: params[:comision])
  #       caballos = params[:caballos]
  #       caballos.each{|cab|
  #         if cab['monto'].to_f > 0 
  #           TablasFijasDetalle.find_by(tablas_fija_id: nuevo.id, caballo_id: cab['id']).update(costo: cab['monto'], status: 1, activo: true)
  #         else 
  #           TablasFijasDetalle.find_by(tablas_fija_id: nuevo.id, caballo_id: cab['id']).update(costo: cab['monto'], status: 2, activo: false)        
  #         end
  #       }
  #     end
  #     render json: {"status" => "OK" }
  #   rescue 
  #     render json: {"status" => "FAILD"}, status: 400
  #   end
  # end

end

