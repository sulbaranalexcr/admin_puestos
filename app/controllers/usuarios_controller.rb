class UsuariosController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_usuarios, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  include ApplicationHelper
  before_action :seguridad_cuentas, only: [:index,:edit, :new]


  def index
    if session[:usuario_actual]['tipo'] == "ADM"
       @usuarios = User.where("tipo <> 'COB'").order(:username)
    elsif session[:usuario_actual]['tipo'] == "INT"
       @usuarios = User.where(tipo: "GRP", grupo_id: Grupo.where(intermediario_id: session[:usuario_actual]['intermediario_id'].to_i).pluck(:id) ).order(:username)
    elsif session[:usuario_actual]['tipo'] == "GRP"
       @usuarios = User.where(tipo: "COB", grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:username)
    end
  end

  def show
  end

  def new
    @cobradores = Cobradore.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:nombre)
    @usuario = User.new
    @url = usuarios_path

  end

  def create
    @usuario = User.new(usuarios_params)
    if @usuario.save
      flash[:notice] = 'Usuario creado.'
      respond_to do |format|
        format.html { redirect_to '/usuarios/' + @usuario.id.to_s + '/edit' }
        format.json { head :no_content }
      end
    end
  end

  def edit
    @usuario = User.find(params[:id])
    menu = MenuUsuario.find_by(user_id: params[:id])
    if menu.present?
        menu_actual = JSON.parse(menu.menu)
        menu_completo = get_menu_original()
        menu_completo.each{|men,value|
          id = value['id']['id'].to_i
          if menu_actual.key?("#{men}")
            value['id']['activo'] = menu_actual["#{men}"]['id']['activo']
            value['menu'].each{|subm|
              id2 = subm['id'].to_i
              busqueda1 = menu_actual["#{men}"]['menu'].select { |x| x["id"].to_i == id2 }
              if busqueda1.present?
                 subm['activo'] = busqueda1[0]['activo']
              end
            }
          end
        }
      @menu_completo = menu_completo
    else
      @menu_completo = get_menu_original()
    end
    @url = usuario_path(@usuario)
  end



  def buscar_tipo
    @usuario = User.find(params[:id])
    menu = MenuUsuario.find_by(user_id: params[:id])
    if menu.present?
      @menu_completo = JSON.parse(menu.menu)
    else
      @menu_completo = get_menu_original()
    end
    @tipo = params[:tipo]
    render partial: 'usuarios/menu',  layout: false
  end

  def update
    menu_actual = JSON.parse(params[:datos_menu])
    menu_completo = get_menu_original()
    menu_completo.each{|men,value|
      id = value['id']['id'].to_i
      busqueda0 =  menu_actual.select { |x| x["principal"].to_i == id }
      if busqueda0.present?
        value['id']['activo'] = busqueda0[0]['check']
      end
      value['menu'].each{|subm|
        busqueda1 = menu_actual.select { |x| x["principal"].to_i == id }
        if busqueda1.present?
           busqueda2 = busqueda1[0]['subs'].select { |x| x["sub"].to_i == subm['id'].to_i }
           if busqueda2.present?
             busqueda3 = busqueda2[0]['check']
             subm['activo'] = busqueda3
           end
        end
      }

    }
    if @usuario.update(usuarios_params)
      busmenu = MenuUsuario.find_by(user_id: @usuario.id)
      if busmenu.present?
        busmenu.update(menu: menu_completo.to_json)
      else
        MenuUsuario.create(user_id: @usuario.id, menu: menu_completo.to_json)
      end
      flash[:notice] = 'Usuario actualizado.'
      respond_to do |format|
        format.html { redirect_to '/usuarios' }
        format.json { head :no_content }
      end
    end

  end


  def buscar_por_grupo
      id = params[:id].to_i
      @usuarios = User.where(grupo_id: id).order(:username)
      render partial: 'taquillas/cuerpo',  layout: false
  end


  private def set_usuarios
    @usuario = User.find(params[:id])
  end


  private def usuarios_params
    params.require(:user).permit(:username, :password, :tipo, :grupo_id, :intermediario_id, :cobrador_id,:activo)
  end




end
