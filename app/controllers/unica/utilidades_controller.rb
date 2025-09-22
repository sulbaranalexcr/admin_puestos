module Unica
  class UtilidadesController < ApplicationController
    skip_before_action :verify_authenticity_token


    def prospectos
      @prospecto = Prospecto.last
    end

    def preview_video
      response.headers.delete('X-Frame-Options')
      id = params[:id]
      ruta = RutaVideo.find_by(id: id)
      if ruta.present?
        @ruta = ruta.url.gsub('/watch?v=', '/embed/')
        render partial: 'preview_video'
      else
        render json: { 'error' => 'No hay ruta' }, status: 400
      end
    end

    def cambiar_ruta_video
      if params[:tipo].to_s.strip == 'delete'
        RutaVideo.destroy_all
      else
        buscar_ruta = RutaVideo.last
        if buscar_ruta.nil?
          RutaVideo.create(nombre: params[:nombre], url: params[:ruta])
        else
          RutaVideo.last.update(nombre: params[:nombre], url: params[:ruta])
        end
      end
      render json: { 'status' => 'ok' }
    end

    def cambiar_nombre_equipos
      render action: 'cambiar_nombre_equipos'
    end

    def buscar_ligas
      equipos_ids = Equipo.all.pluck(:liga_id).uniq
      @ligas = Liga.where(juego_id: params[:id], liga_id: equipos_ids).order(:nombre)
      ligas_sin_cambios = []
      @ligas_sin = []
      @ligas.each do |lig|
        eqps = Equipo.where(liga_id: lig.liga_id)
        eqps.each do |eq|
          ligas_sin_cambios << lig.nombre if eq.nombre == eq.nombre_largo
        end
      end
      @ligas_sin = ligas_sin_cambios.uniq if ligas_sin_cambios.length > 0
      render partial: '/unica/utilidades/div_ligas'
    end

    def buscar_equipos
      @equipos = Equipo.where(liga_id: params[:id]).order(:id)
      render partial: 'equipos', layout: false
    end

    def cambiar_nombre_ind
      liga_id = params[:liga_id]
      id = params[:id]
      nom_lar = params[:nom_lar]
      nom_cor = params[:nom_cor]
      Equipo.find(id).update(nombre: nom_cor)
      matchs = Match.where("local > now() and data ilike '%#{nom_lar}%'")
      if matchs.present?
        matchs.each do |dat|
          cambio = false
          datos = JSON.parse(dat.data)
          datos['money_line']['c'].each do |ml_data|
            if ml_data['t'] == nom_lar
              ml_data['t'] = nom_cor
              cambio = true
            end
          end
          dat.update(data: datos.to_json) if cambio
        end
      end
    end

    def exchange_rates
      bus_data = ExchangeRate.last
      @data = []
      @data = ExchangeRate.last if bus_data.present?
    end

    def exchange_rate_import
      require 'net/http'
      uri = URI.parse("http://api.currencylayer.com/live?access_key=#{ENV['EXCHANGE_API_KEY']}")
      uri.query = URI.encode_www_form({})
      res = Net::HTTP.get_response(uri)
      ExchangeRate.create(data: JSON.parse(res.body))
    end

    def search_user
    end

    def examinar_usuario
      users = UsuariosTaquilla.where("cliente_id ~ ?", "^#{params[:id]}(-|$)").pluck(:id, :moneda_default, :simbolo_moneda_default, :alias, :correo)
      render partial: 'user_by_coins', locals: { users: users }
    end
    
    def auditoria
      user_id = params[:id]
      currency_id = params[:currency_id]
      days = params[:dias]
      cl_id = currency_id == '0' ? user_id : "#{user_id}-#{currency_id}"
      user = UsuariosTaquilla.find_by(cliente_id: cl_id)

      involucrado = PropuestasCaballosPuesto.where("id_juega = #{user.id} or id_banquea = #{user.id}")
                                            .where("created_at > now() - '#{days} days'::interval")
                                            .count
      cruzadas = PropuestasCaballosPuesto.where("id_juega = #{user.id} or id_banquea = #{user.id}").where(status: 2)
                                         .where("created_at > now() - '#{days} days'::interval")
                                         .count
      jugo = PropuestasCaballosPuesto.where("id_juega = #{user.id} and id_propone = #{user.id}").where(status: 2)
                                     .where("created_at > now() - '#{days} days'::interval")
                                     .count
      banqueo = PropuestasCaballosPuesto.where("id_banquea = #{user.id} and id_propone = #{user.id}").where(status: 2)
                                        .where("created_at > now() - '#{days} days'::interval")
                                        .count
      win_jugo = PropuestasCaballosPuesto.where("id_juega = #{user.id} and id_gana = #{user.id}")
                                         .where("created_at > now() - '#{days} days'::interval")
                                         .count
      win_banquea = PropuestasCaballosPuesto.where("id_banquea = #{user.id} and id_gana = #{user.id}")
                                            .where("created_at > now() - '#{days} days'::interval")
                                            .count
      max_win = PropuestasCaballosPuesto.where("id_gana = #{user.id}")
                                        .where("created_at > now() - '#{days} days'::interval")
                                        .order(Arel.sql("CASE WHEN id_gana = id_propone THEN cuanto_gana_completo ELSE monto END"))
                                        .last
      contra_win = PropuestasCaballosPuesto.where("id_gana = #{user.id}")
                                           .where("created_at > now() - '#{days} days'::interval")
                                           .order(Arel.sql("CASE WHEN id_gana = id_propone THEN cuanto_gana_completo ELSE monto END"))
     
      array_gana = []
      contra_win.each do |dat|
        bus = UsuariosTaquilla.find_by(id: dat.id_gana == dat.id_juega ? dat.id_banquea : dat.id_juega)
        array_gana << { 
          "fecha" => dat.created_at.strftime("%d/%m/%Y %I:%M %p"),
          "texto" => dat.texto_jugada, 
          "monto" => (dat.id_gana == dat.id_propone && dat.id_juega == dat.id_propone) ? dat.monto.to_f : dat.cuanto_gana_completo.to_f,
          "pierde" => bus.cliente_id, 
          "monto_pierde" => (dat.id_gana == dat.id_propone && dat.id_juega == dat.id_propone) ? dat.cuanto_gana_completo.to_f : dat.monto.to_f,
        }
      end

      obj = {
        "id" => user.id,
        "creado" => user.created_at,
        "involucrado" => involucrado,
        "cruzadas" => cruzadas,
        "ganadas" =>  win_jugo + win_banquea,
        "jugo" => jugo,
        "banqueo" => banqueo,
        "win_jugo" => win_jugo,
        "win_banquea" => win_banquea,
        "max_win" => max_win..present? ? (max_win.id_gana == max_win.id_juega ? max_win.cuanto_gana_completo.to_f : max_win.monto.to_f) : 0,
        "jugadas" => array_gana
      }
      render partial: 'auditoria', locals: { obj: obj }
    end
  end
end
