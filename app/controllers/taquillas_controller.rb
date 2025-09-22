class TaquillasController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_taquilla, only: [:show, :edit, :update, :destroy]
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index, :edit, :new]

  def index
    if session[:usuario_actual]["tipo"] == "ADM"
      if params[:all].present?
        @taquillas = UsuariosTaquilla.all.order(:nombre)
      else
        @taquillas = UsuariosTaquilla.where(externo: false).order(:nombre)
      end
    elsif session[:usuario_actual]["tipo"] == "GRP"
      if params[:all].present?
        @taquillas = UsuariosTaquilla.where(grupo_id: session[:usuario_actual]["grupo_id"]).order(:nombre)
      else
        @taquillas = UsuariosTaquilla.where(externo: false, grupo_id: session[:usuario_actual]["grupo_id"]).order(:nombre)
      end
    elsif session[:usuario_actual]["tipo"] == "COB"
      if params[:all].present?
        @taquillas = UsuariosTaquilla.where(cobrador_id: session[:usuario_actual]["cobrador_id"]).order(:nombre)
      else
        @taquillas = UsuariosTaquilla.where(externo: false, cobrador_id: session[:usuario_actual]["cobrador_id"]).order(:nombre)
      end
    end
  end

  def show
    @solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: params[:id])
    @usuario = UsuariosTaquilla.find(params[:id])
    render action: "recargar"
  end

  def new
    @taquilla = UsuariosTaquilla.new
    @grupo_sel = params[:grupo]
    if session[:usuario_actual]["tipo"] == "GRP"
      @grupos = Grupo.where(id: session[:usuario_actual]["grupo_id"])
      busgru = Grupo.find(session[:usuario_actual]["grupo_id"])
      @porcentajet = busgru.porcentaje_taquilla.to_f
      if busgru.propone
        @taquilla.propone = true
      else
        @taquilla.propone = false
      end
      if busgru.toma
        @taquilla.toma = true
      else
        @taquilla.toma = false
      end
    elsif session[:usuario_actual]["tipo"] == "COB"
      @grupos = Grupo.where(id: session[:usuario_actual]["grupo_id"].to_i)
      busgru = Grupo.find(session[:usuario_actual]["grupo_id"])
      @porcentajet = busgru.porcentaje_taquilla.to_f
      if busgru.propone
        @taquilla.propone = true
      else
        @taquilla.propone = false
      end
      if busgru.toma
        @taquilla.toma = true
      else
        @taquilla.toma = false
      end
    elsif session[:usuario_actual]["tipo"] == "ADM"
      @grupos = Grupo.where(id: params[:grupo].to_i)
      busgru = Grupo.find(session[:grupo_select])
      @porcentajet = busgru.porcentaje_taquilla.to_f
      if busgru.propone
        @taquilla.propone = true
      else
        @taquilla.propone = false
      end
      if busgru.toma
        @taquilla.toma = true
      else
        @taquilla.toma = false
      end
    end
    @url = taquillas_path
  end

  def validar_correo
    tipo = params[:tipo].to_i
    if tipo == 2
      user = UsuariosTaquilla.where(correo: params[:correo]).where.not(id: params[:user_id].to_i)
    else
      user = UsuariosTaquilla.where(correo: params[:correo])
    end
    if user.present?
      render json: { "existe" => true }
    else
      render json: { "existe" => false }
    end
  end

  def create
    @taquilla = UsuariosTaquilla.new(taquilla_params.merge!(need_confirm: false))
    user = UsuariosTaquilla.where(correo: params[:usuarios_taquilla][:correo])
    if user.present?
      flash[:notice] = 'Usuarios Ya existe con ese correo.'
      respond_to do |format|
        format.html { redirect_to '/taquillas' }
        format.json { head :no_content }
      end
    else
      if session[:usuario_actual]['tipo'] == 'ADM'
        @taquilla.grupo_id = params[:usuarios_taquilla][:grupo_id].to_i
        @taquilla.cobrador_id = params[:usuarios_taquilla][:cobrador_id]
        buscar_factorc = FactorCambio.find_by(cobrador_id: params[:usuarios_taquilla][:cobrador_id])
        @taquilla.moneda_default = if buscar_factorc
                                     buscar_factorc.moneda_id
                                   else
                                     2
                                   end
        @taquilla.moneda_default_dolar = if buscar_factorc
                                           buscar_factorc.valor_dolar
                                         else
                                           1
                                         end
      end

      if session[:usuario_actual]['tipo'] == 'GRP'
        @taquilla.grupo_id = session[:usuario_actual]['grupo_id'].to_i
        @taquilla.cobrador_id = params[:usuarios_taquilla][:cobrador_id]
        buscar_factorc = FactorCambio.find_by(cobrador_id: params[:usuarios_taquilla][:cobrador_id])
        @taquilla.moneda_default = if buscar_factorc
                                     buscar_factorc.moneda_id
                                   else
                                     2
                                   end
        @taquilla.moneda_default_dolar = if buscar_factorc
                                           buscar_factorc.valor_dolar
                                         else
                                           1
                                         end
      end
      if session[:usuario_actual]['tipo'] == 'COB'
        @taquilla.grupo_id = Cobradore.find(session[:usuario_actual]['cobrador_id']).grupo_id
        @taquilla.cobrador_id = session[:usuario_actual]['cobrador_id']
        buscar_factorc = FactorCambio.find_by(cobrador_id: session[:usuario_actual]['cobrador_id'])
        @taquilla.moneda_default = if buscar_factorc
                                     buscar_factorc.moneda_id
                                   else
                                     2
                                   end
        @taquilla.moneda_default_dolar = if buscar_factorc
                                           buscar_factorc.valor_dolar
                                         else
                                           1
                                         end
      end

      @taquilla.id_agente = "SB-#{params[:usuarios_taquilla][:cobrador_id]}"
      @taquilla.externo = true
      @taquilla.tipo = params[:usuarios_taquilla][:tipotaq].to_i
      @taquilla.status = 1
      @taquilla.saldo_bs = 0
      @taquilla.saldo_usd = 0
      integrador = Integrador.find_by(id: Cobradore.find(params[:usuarios_taquilla][:cobrador_id]).integrador_id)
      @taquilla.integrador_id = integrador.present? ? integrador.id : nil
      clave = @taquilla.clave
      @taquilla.clave = Digest::MD5.hexdigest(clave)
      nueva_taq = @taquilla
      if nueva_taq.save
        if session[:usuario_actual]['tipo'] == 'COB'
          taqs = []
          buscob = Cobradore.find(session[:usuario_actual]['cobrador_id'])
          nueva_taq.update(moneda_default: buscob.moneda_id, simbolo_moneda_default: buscob.moneda)
          if buscob.usuarios_taquilla_id.present?
            taqs = JSON.parse(buscob.usuarios_taquilla_id)
            taqs << nueva_taq.id
            buscob.update(usuarios_taquilla_id: taqs.to_json)
          else
            taqs << nueva_taq.id
          end
          buscob.update(usuarios_taquilla_id: taqs.to_json)
        end
        if session[:usuario_actual]['tipo'] == 'GRP'
          taqs = []
          buscob = Cobradore.find(params[:usuarios_taquilla][:cobrador_id])
          nueva_taq.update(moneda_default: buscob.moneda_id, simbolo_moneda_default: buscob.moneda)
          if buscob.usuarios_taquilla_id.present?
            taqs = JSON.parse(buscob.usuarios_taquilla_id)
            taqs << nueva_taq.id
            buscob.update(usuarios_taquilla_id: taqs.to_json)
          else
            taqs << nueva_taq.id
            buscob.update(usuarios_taquilla_id: taqs.to_json)
          end
        end

        Estructura.create(nombre: params[:usuarios_taquilla][:alias], representante: nueva_taq.grupo.nombre, telefono: params[:usuarios_taquilla][:telefono], correo: params[:usuarios_taquilla][:correo], rif: params[:usuarios_taquilla][:cedula], tipo: 4, tipo_id: nueva_taq.id, padre_id: nueva_taq.grupo.estructura_id, activo: params[:usuarios_taquilla][:activo])
        flash[:notice] = 'UsuariosTaquilla creado.'
        respond_to do |format|
          format.html { redirect_to '/taquillas' }
          format.json { head :no_content }
        end
      else
        nueva_taq.errors.inspect
        Rails.logger.error(nueva_taq.errors.inspect)
        Rails.logger.error(nueva_taq.errors)
      end
    end
  end

  def edit
    @taquilla = UsuariosTaquilla.find(params[:id])
    @url = taquilla_path(@taquilla)
  end

  def update
    if @taquilla.update(taquilla_params2)
      integrador = Integrador.find_by(grupo_id: @taquilla.grupo_id)
      @taquilla.integrador_id = integrador.present? ? integrador.id : nil
      @taquilla.save
      if session[:usuario_actual]["tipo"] == "GRP"
        buscar_factorc = FactorCambio.find_by(cobrador_id: params[:usuarios_taquilla][:cobrador_id])
        if buscar_factorc
          @taquilla.update(cobrador_id: params[:usuarios_taquilla][:cobrador_id], moneda_default: buscar_factorc.moneda_id)
        else
          @taquilla.update(cobrador_id: params[:usuarios_taquilla][:cobrador_id], moneda_default: 2)
        end
      end
      if session[:usuario_actual]["tipo"] == "COB"
        buscar_factorc = FactorCambio.find_by(cobrador_id: session[:usuario_actual]["cobrador_id"])
        if buscar_factorc
          @taquilla.update(moneda_default: buscar_factorc.moneda_id)
        else
          @taquilla.update(moneda_default: 2)
        end
      end

      Estructura.where(tipo: 4, tipo_id: @taquilla.id).update(nombre: params[:usuarios_taquilla][:nombre], representante: @taquilla.grupo.nombre, telefono: params[:usuarios_taquilla][:telefono], correo: params[:usuarios_taquilla][:correo], rif: params[:usuarios_taquilla][:cedula], padre_id: @taquilla.grupo.estructura_id, activo: params[:usuarios_taquilla][:activo])
      clave_vieja = @taquilla.clave
      clave_nueva = params[:usuarios_taquilla][:clave]
      if clave_vieja != clave_nueva
        @taquilla.update(clave: Digest::MD5.hexdigest(clave_nueva))
      end

      if params[:usuarios_taquilla]['activo'].to_i  == 0
        ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "BLOQUEAR_TAQUILLA", "taq_id" => params[:id], "grupo_id" => 0, "cobrador_id" => 0 }}
      end

      flash[:notice] = "Taquilla actualizada."
      respond_to do |format|
        format.html { redirect_to "/taquillas" }
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
    session[:grupo_select] = id
    render partial: "taquillas/cuerpo", layout: false
  end

  #
  # def recarga
  # end

  def verificar_recarga
    @solicitudes = SolicitudRecarga.where(usuarios_taquilla_id: params[:id])
    @usuario = UsuariosTaquilla.find(params[:id])
    if @solicitudes.count > 0
      # render json: {"msg" => "Todo bien."}
      redirect_to controller: "thing", action: "edit", id: 3, something: "else"
    else
      render json: { "msg" => "El cliente no tiene solicitudes." }, status: 400
    end
  end

  private
  def set_taquilla
    @taquilla = UsuariosTaquilla.find(params[:id])
  end

  def taquilla_params
    params.require(:usuarios_taquilla).permit(:nombre, :cedula, :alias, :telefono, :correo, :activo, :grupo_id, :comision, :clave, :jugada_minima_bs, :jugada_maxima_bs, :jugada_minima_usd, :jugada_maxima_usd, :propone, :toma, :usa_cajero_externo, :cobrador_id, :demo)
  end

  def taquilla_params2
    params.require(:usuarios_taquilla).permit(:nombre, :cedula, :alias, :telefono, :correo, :activo, :grupo_id, :comision, :jugada_minima_bs, :jugada_maxima_bs, :jugada_minima_usd, :jugada_maxima_usd, :propone, :toma, :usa_cajero_externo, :cobrador_id, :demo)
  end

  # UsuariosTaquilla.all.each{|taq|
  #   buscar = Estructura.find_by(tipo: 4, tipo_id: taq.id)
  #   unless buscar.present?
  #     Estructura.create(nombre: taq.alias, representante: taq.grupo.nombre, telefono: taq.telefono, correo: taq.correo, rif: taq.cedula, tipo: 4, tipo_id: taq.id, padre_id: taq.grupo.estructura_id, activo: true)
  #   end
  # }

end
