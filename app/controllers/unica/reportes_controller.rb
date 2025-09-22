module Unica
  class ReportesController < ApplicationController
    include ActionView::Helpers::NumberHelper
    before_action :check_user_auth,
                  only: %i[cuadre_general premios_ingresados_index posttime solicitudes movimientos]
    skip_before_action :verify_authenticity_token
    before_action :seguridad_cuentas,
                  only: %i[cuadre_general cuadre_general_grupo premios_ingresados_index posttime solicitudes
                           movimientos]

    def jugadas_taquilla
      @taquillas = UsuariosTaquilla.all.order(:nombre)
    end

    def set_user_data(user_id)
      user_consulta = UsuariosTaquilla.find(user_id)
      moneda_def = user_consulta.moneda_default_dolar.to_f
      @valor_moneda = moneda_def.positive? ? moneda_def : 1
      @simbolo_moneda_default = user_consulta.simbolo_moneda_default
      @nombre_cliente = user_consulta.nombre
      @correo_cliente = user_consulta.correo
    end

    def jugadas_taquilla2
      fecha = params[:desde]
      jugo = 'jugo'
      banqueo = 'banqueo'
      @idioma = params[:idioma]
      @fecha = fecha
      jugadas_todas = []
      deporte_id = 0
      liga_id = 0
      match_id = 0
      tipo_repor = params[:tipo].to_i
      ticket_id = params[:t_id].to_i
      zona = params[:zona]
      @nombre_cliente = ''

      if tipo_repor == 1
        user_id = params[:taquilla_id].to_i
        set_user_data(user_id)
        jugadas = PropuestasDeporte.where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
        jugadas += PropuestasDeporte.where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
        jugadas += PropuestasCaballo.where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
        jugadas += PropuestasCaballo.where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
        jugadas += PropuestasCaballosPuesto.where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
        jugadas += PropuestasCaballosPuesto.where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      else
        detalle_ticket = TicketsDetalle.find_by(id: ticket_id)
        render json: { 'mensaje' => 'Ticket no encontrado' }, status: 400 and return unless detalle_ticket.present?

        ticket = detalle_ticket.ticket
        user_id = ticket.usuarios_taquilla_id.to_i
        set_user_data(user_id)
        origen = detalle_ticket.origin_propuesta
        jugadas = Object.const_get(origen).where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
        jugadas += Object.const_get(origen).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
        jugadas = jugadas.select { |jugx| jugx.tickets_detalle_id_juega == ticket_id || jugx.tickets_detalle_id_banquea == ticket_id }
      end
      valor_moneda = @valor_moneda
      # if deporte_id.positive? && liga_id.zero? && match_id.zero?
      #   case deporte_id
      #   when 998
      #     jugadas = PropuestasCaballo.where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballo.where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,2,3,6,7,8,9,10,11,12,13,14)').order(:id)
      #   when 997
      #     jugadas = PropuestasCaballosPuesto.where(id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballosPuesto.where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,2,3,6,7,8,9,10,11,12,13,14)').order(:id)
      #   else
      #     jugadas = PropuestasDeporte.where(deporte_id: deporte_id,
      #                                       id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasDeporte.where.not(deporte_id: deporte_id,
      #                                            id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id) end
      # end
      # if deporte_id.positive? && liga_id.positive? && match_id.zero?
      #   case deporte_id
      #   when 998
      #     jugadas = PropuestasCaballo.where(hipodromo_id: liga_id,
      #                                       id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballo.where(hipodromo_id: liga_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   when 997
      #     jugadas = PropuestasCaballosPuesto.where(hipodromo_id: liga_id,
      #                                              id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballosPuesto.where(hipodromo_id: liga_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   else
      #     jugadas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id,
      #                                       id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasDeporte.where(deporte_id: deporte_id,
      #                                        liga_id: liga_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   end
      # end
      # if deporte_id.positive? && liga_id.positive? && match_id.positive?
      #   case deporte_id
      #   when 998
      #     jugadas = PropuestasCaballo.where(hipodromo_id: liga_id, carrera_id: match_id,
      #                                       id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballo.where(hipodromo_id: liga_id,
      #                                        carrera_id: match_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   when 997
      #     jugadas = PropuestasCaballosPuesto.where(hipodromo_id: liga_id, carrera_id: match_id,
      #                                              id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasCaballosPuesto.where(hipodromo_id: liga_id,
      #                                               carrera_id: match_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   else
      #     jugadas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,
      #                                       id_propone: user_id).where(created_at: fecha.to_time.all_day).where('status2 in (1,2,4,6,7,8,9,10,11,12,13,14) and corte_id = 0').order(:id)
      #     jugadas += PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id,
      #                                        match_id: match_id).where.not(id_propone: user_id).where("id_juega = #{user_id} or id_banquea = #{user_id}").where(created_at: fecha.to_time.all_day).where('status2 in (1,3,  2,6,7,8,9,10,11,12,13,14)').order(:id)
      #   end
      # end
      jugadas.each do |jug|
        jug.status2 = 4 if jug.status2 == 3 && jug.id_propone != user_id

        jug.status2 = 2 if jug.status2 == 4 && jug.id_propone != user_id

        jug.status2 = 9 if jug.status2 == 8 && jug.id_gana != user_id

        jug.status2 = 12 if jug.status2 == 11 && jug.id_gana != user_id
        jug.created_at = jug.created_at.in_time_zone(zona) if zona != 'America/Caracas'
        jug.monto = if jug.id_propone == jug.id_juega
                      jug.monto * valor_moneda
                    else
                      jug.cuanto_gana_completo * valor_moneda
                    end

        jugadas_todas2 = []
        if jug.status2 == 4
          jugadas2 = jug.hijas
          jugadas2.each do |jug2|
            otro_user = ''
            otro = jug2.id_juega.to_i == user_id.to_i ? jug2.id_banquea.to_i : jug2.id_juega.to_i
            otro_user = UsuariosTaquilla.find(otro).nombre if otro.positive?
            jug2.status2 = 9 if (jug2.status2 == 8) && (jug2.id_gana != user_id)
            jug2.status2 = 12 if (jug2.status2 == 11) && (jug2.id_gana != user_id)
            jug2.created_at = jug2.created_at.in_time_zone(zona) if zona != 'America/Caracas'
            jug2.monto = if jug2.id_propone == jug2.id_juega
                           jug2.monto * valor_moneda
                         else
                           jug2.cuanto_gana_completo * valor_moneda
                         end
            if jug.usa_igual_accion
              if jug.cruzo_igual_accion && (jug.id_propone != user_id)
                if jug2.status != 4
                  jugadas_todas2 << { 'id' => jug2.id,
                                      'jugada_completa' => " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   <i class='fa fa-minus' aria-hidden='true'></i>  &nbsp; <font color='gray'>" + jug2.texto_igual_condicion + '</font>', 'moneda' => 2, 'status2' => jug2.status2, 'created_at' => jug2.created_at, 'monto' => jug2.monto, 'corte_id' => jug2.corte_id, 'otro' => otro_user }
                end
              elsif jug2.status != 4
                jugadas_todas2 << { 'id' => jug2.id,
                                    'jugada_completa' => " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   <i class='fa fa-minus' aria-hidden='true'></i>  &nbsp; <font color='gray'>" + jug2.texto_jugada + '</font>', 'moneda' => 2, 'status2' => jug2.status2, 'created_at' => jug2.created_at, 'monto' => jug2.monto, 'corte_id' => jug2.corte_id, 'otro' => otro_user }
              end
            elsif jug2.status != 4
              jugadas_todas2 << { 'id' => jug2.id,
                                  'jugada_completa' => " &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   <i class='fa fa-minus' aria-hidden='true'></i>  &nbsp; <font color='gray'>" + jug2.texto_jugada + '</font>', 'moneda' => 2, 'status2' => jug2.status2, 'created_at' => jug2.created_at, 'monto' => jug2.monto, 'corte_id' => jug2.corte_id, 'otro' => otro_user }
            end
          end
        end
        titulo = if jug.accion_id == 1
                   if jug.id_propone == user_id
                     jugo
                   else
                     banqueo
                   end
                 elsif jug.id_propone == user_id
                   banqueo
                 else
                   jugo
                 end

        transaction_id = jug.id_juega == user_id ? jug.tickets_detalle_id_juega : jug.tickets_detalle_id_banquea

        if jug.usa_igual_accion
          if jug.cruzo_igual_accion && (jug.id_propone != user_id)
            titulo = if jug.accion_id == 1
                       jugo
                     else
                       banqueo
                     end
            jugadas_todas << { 'transaction_id' => transaction_id, 'id' => jug.id,
                               'jugada_completa' => "#{jug.texto_igual_condicion}  ", 'moneda' => 2, 'status2' => jug.status2, 'created_at' => jug.created_at, 'monto' => jug.monto, 'corte_id' => jug.corte_id, 'titulo' => titulo, 'hijos' => jugadas_todas2 }
          else
            jugadas_todas << { 'transaction_id' => transaction_id, 'id' => jug.id,
                               'jugada_completa' => "#{jug.texto_jugada}  ", 'moneda' => 2, 'status2' => jug.status2, 'created_at' => jug.created_at, 'monto' => jug.monto, 'corte_id' => jug.corte_id, 'titulo' => titulo, 'hijos' => jugadas_todas2 }
          end
        else
          jugadas_todas << { 'transaction_id' => transaction_id, 'id' => jug.id,
                             'jugada_completa' => "#{jug.texto_jugada}  ", 'moneda' => 2, 'status2' => jug.status2, 'created_at' => jug.created_at, 'monto' => jug.monto, 'corte_id' => jug.corte_id, 'titulo' => titulo, 'hijos' => jugadas_todas2 }
        end
      end
      @jugadas = jugadas_todas.sort_by { |value| value['created_at'] }
      render partial: 'unica/reportes/jugadas_taquilla', layout: false
    end

    def cuadre_general
      render action: 'cuadre_general'
    end

    def cuadre_general_por_grupo
      tipo = 'ADM'
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @reporte = []
      Grupo.all.order(:nombre).each do |grp|
        jugado_bs = 0
        jugado_usd = 0
        ganado_bs = 0
        ganado_usd = 0
        porcentaje_bg_bs = 0
        porcentaje_bg_usd = 0
        reporte = ActiveRecord::Base.connection.execute("select (select (sum(monto) * -1) as monto from operaciones_cajeros where moneda = 1 and tipo in (1,2) and usuarios_taquilla_id = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp) as jugado_bs ,(select sum(monto) * -1 as monto from operaciones_cajeros where tipo in (1,2) and usuarios_taquilla_id = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2) as jugado_usd, (select sum(monto_pagado_completo) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp  and moneda = 1 ) as ganado_bs, (select sum(monto_pagado_completo) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2 ) as ganado_usd, (select sum((monto_pagado_completo * porcentaje_bg)/100) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp  and moneda = 1 ) as porcentaje_bg_bs, (select sum((monto_pagado_completo * porcentaje_bg)/100) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2 ) as porcentaje_bg_usd from usuarios_taquillas where grupo_id = #{grp.id}")
        reporte.each do |rrp|
          jugado_bs += rrp['jugado_bs'].to_f
          jugado_usd += rrp['jugado_usd'].to_f
          ganado_bs += rrp['ganado_bs'].to_f
          ganado_usd += rrp['ganado_usd'].to_f
          porcentaje_bg_bs += rrp['porcentaje_bg_bs'].to_f
          porcentaje_bg_usd += rrp['porcentaje_bg_usd'].to_f
        end

        if reporte.cmd_tuples > 0
          @reporte << { 'id' => grp.id, 'comision_bs' => porcentaje_bg_bs, 'comision_usd' => porcentaje_bg_usd,
                        'nombre' => grp.nombre, 'jugado_bs' => jugado_bs.to_f, 'jugado_usd' => jugado_usd.to_f, 'ganado_bs' => ganado_bs.to_f, 'ganado_usd' => ganado_usd.to_f }
        else
          @reporte << { 'id' => grp.id, 'comision_bs' => porcentaje_bg_bs, 'comision_usd' => porcentaje_bg_usd,
                        'nombre' => grp.nombre, 'jugado_bs' => 0, 'jugado_usd' => 0, 'ganado_bs' => 0, 'ganado_usd' => 0 }
        end
      end
      render partial: 'reportes/general_por_grupo', layout: false
    end

    def cuadre_general_caballos
      render action: 'cuadre_general_caballos'
    end

    def cuadre_general_por_grupo_caballos
      tipo = 'ADM'
      @nombre_reporte_titulo = 'Taquillas'
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @tipo_cruzado = 'Cruzado'
      @tipo_reporte_url = if session[:usuario_actual]['tipo'] == 'ADM'
                            'GRP'
                          else
                            'COB'
                          end
      @desde = params[:desde].to_time.strftime('%d/%m/%Y')
      @hasta = params[:hasta].to_time.strftime('%d/%m/%Y')
      @reporte = []
      estructuras1 = []
      estructuras2 = []
      tipo_user = 0
      case session[:usuario_actual]['tipo']
      when 'ADM'
        estructuras1 = Estructura.where(tipo: 2).order(:nombre).pluck(:id)
        estructuras2 = Estructura.where(tipo: 3,
                                        tipo_id: Grupo.where(intermediario_id: 0).ids).order(:nombre).pluck(:id)
        estructuras = estructuras1 + estructuras2
      when 'INT'
        tipo_user = 2
        estructuras = Estructura.where(tipo: 3,
                                       tipo_id: Grupo.where(intermediario_id: session[:usuario_actual]['intermediario_id']).ids).order(:nombre).pluck(:id)
      when 'GRP'
        @tipo_cruzado = 'Jugado'
        @porcentaje_banca = Grupo.find(session[:usuario_actual]['grupo_id']).porcentaje_banca.to_f
        tipo_user = 3
        estructuras = Estructura.where(tipo: 4,
                                       tipo_id: UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id']).ids).order(:nombre).pluck(:id)
      when 'COB'
        @tipo_cruzado = 'Jugado'
        tipo_user = 3
        estructuras = Estructura.where(tipo: 4,
                                       tipo_id: JSON.parse(Cobradore.find(session[:usuario_actual]['cobrador_id']).usuarios_taquilla_id)).order(:nombre).pluck(:id)
      end

      jugado_bs = 0
      jugado_usd = 0
      ganado_bs = 0
      ganado_usd = 0
      porcentaje_bg_bs = 0
      porcentaje_bg_usd = 0
      @nombre_reporte_mostrar = ''
      #  reporte1 = CuadreGeneralCaballo.select("cuadre_general_caballos.*,(select nombre from estructuras where estructuras.id = cuadre_general_caballos.estructura_id) as nombre").where(estructura_id: estructuras, moneda: 1).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp").order(:estructura_id)
      case params[:tipo].to_i
      when 0
        @nombre_reporte_mostrar = 'Cuadre General'
        reporte1 = CuadreGeneralCaballosPuesto.select('cuadre_general_caballos_puestos.*,(select nombre from estructuras where estructuras.id = cuadre_general_caballos_puestos.estructura_id) as nombre').where(
          estructura_id: estructuras, moneda: 2
        ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp").order(:estructura_id)
        Rails.logger.info '***************'
        Rails.logger.info reporte1.to_json
        Rails.logger.info '***************'
        reporte2 = reporte1
        #+ reporte0
      when 1
        @nombre_reporte_mostrar = 'Cuadre por Caballos'
        reporte2 = CuadreGeneralCaballosPuesto.select('cuadre_general_caballos_puestos.*,(select nombre from estructuras where estructuras.id = cuadre_general_caballos_puestos.estructura_id) as nombre').where(
          estructura_id: estructuras, moneda: 2
        ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp").order(:estructura_id)
      when 2
        @nombre_reporte_mostrar = 'Cuadre por Deportes'
        reporte2 = CuadreGeneralDeporte.select('cuadre_general_deportes.*,(select nombre from estructuras where estructuras.id = cuadre_general_deportes.estructura_id) as nombre').where(
          estructura_id: estructuras, moneda: 2
        ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp").order(:estructura_id)
      end

      reporte2.length.times do |t|
        tipo = ''
        tipo = if estructuras1.include?(reporte2[t].estructura_id.to_i)
                 'INT'
               elsif estructuras2.include?(reporte2[t].estructura_id.to_i)
                 'GRP'
               else
                 case tipo_user
                 when 2
                   'GRP'
                 when 3
                   'TAQ'
                 else
                   ''
                 end
               end
        if reporte2[t].venta.to_f > 0
          @reporte << { 'id' => reporte2[t].estructura_id, 'nombre' => reporte2[t].nombre,
                        'venta' => reporte2[t].venta.to_f, 'premio' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'tipo' => tipo }
        end
      end

      @reporte = @reporte.group_by { |r| r['id'] }.map do |_, v|
        v.each_with_object(v.shift.dup) do |r, a|
          a['venta'] += r['venta']
          a['premio'] += r['premio']
          a['gano_oc'] += r['gano_oc']
          a['perdio_oc'] += r['perdio_oc']
          a['comision'] += r['comision']
          a['comision_oc'] += r['comision_oc']
        end
      end

      # logger.info("***************************************************")
      # logger.info(@reporte.length)
      # logger.info("***************************************************")
      @reporte = @reporte.sort_by { |k| k['nombre'] }
      respond_to do |format|
        format.html do
          render partial: 'unica/reportes/general_por_grupo_caballos_taq', layout: false
        end
        format.pdf do
          render pdf: 'cuadre_general', page_size: 'Letter',
                 template: 'reportes/general_por_grupo_caballos_taq.pdf.erb',
                 font_size: 8,
                 footer: { center: 'Pag: [page] de [topage]' }
        end
        format.xlsx do
          response.headers[
            'Content-Disposition'
          ] = "attachment; filename=cuadre_general_taquillas_#{@desde}_#{@hasta}.xlsx"
        end
      end
    end

    def cuadre_general_por_grupo_cobradores
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @tipo_cruzado = 'Cruzado'
      @nombre_reporte_titulo = 'Agentes'
      @desde = params[:desde].to_time.strftime('%d/%m/%Y')
      @hasta = params[:hasta].to_time.strftime('%d/%m/%Y')
      @reporte = []
      estructuras1 = []
      estructuras2 = []
      tipo_user = 0
      @tipo_cruzado = 'Jugado'
      @porcentaje_banca = Grupo.find(session[:usuario_actual]['grupo_id']).porcentaje_banca.to_f

      tipo_user = 3
      buscar_tipo = if session[:usuario_actual]['tipo'] == 'GRP'
                      Cobradore.where(grupo_id: session[:usuario_actual]['grupo_id']).order(:nombre)
                    else
                      Cobradore.where(id: session[:usuario_actual]['cobrador_id']).order(:nombre)
                    end
      buscar_tipo.each do |cob|
        taqs = []
        taqs = JSON.parse(cob.usuarios_taquilla_id) if cob.usuarios_taquilla_id.present?
        estructuras = Estructura.where(tipo: 4, tipo_id: taqs).order(:nombre).pluck(:id)
        jugado_bs = 0
        jugado_usd = 0
        ganado_bs = 0
        ganado_usd = 0
        porcentaje_bg_bs = 0
        porcentaje_bg_usd = 0
        reporte2 = CuadreGeneralCaballo.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
          estructura_id: estructuras, moneda: 2
        ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
        reporte2.length.times do |t|
          tipo = 'COB'
          @tipo_reporte2url = 'COB'
          @reporte << { 'id' => cob.id, 'nombre' => cob.nombre + ' ' + cob.apellido,
                        'venta' => reporte2[t].venta.to_f, 'premio' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'monto_otro_grupo' => reporte2[t].monto_otro_grupo.to_f, 'tipo' => tipo, 'comision_banca' => cob.comision_banca.to_f }
        end
      end

      @reporte = @reporte.group_by { |r| r['id'] }.map do |_, v|
        v.each_with_object(v.shift.dup) do |r, a|
          a['venta'] += r['venta']
          a['premio'] += r['premio']
          a['gano_oc'] += r['gano_oc']
          a['perdio_oc'] += r['perdio_oc']
          a['comision'] += r['comision']
          a['comision_oc'] += r['comision_oc']
          a['monto_otro_grupo'] += r['monto_otro_grupo']
        end
      end
      #  @reporte = @reporte.sort_by { |k| k["nombre"] }
      respond_to do |format|
        format.html do
          render partial: 'reportes/general_por_grupo_caballos_cob', layout: false
        end
        format.pdf do
          render pdf: 'cuadre_general', page_size: 'Letter',
                 template: 'reportes/general_por_grupo_caballos_cob.pdf.erb',
                 font_size: 8,
                 footer: { center: 'Pag: [page] de [topage]' }
        end
        format.xlsx do
          response.headers[
            'Content-Disposition'
          ] = "attachment; filename=cuadre_general_agente_#{@desde}_#{@hasta}.xlsx"
        end
      end
    end

    def validar_integrador(integrator_id, api_key)
      Integrador.find_by(id: integrator_id, api_key: api_key)
    end

    def cuadre_general_api
      integrator_id = params[:integrator_id]
      api_key = params[:api_key]
      user_name = params[:user_name]
      integrador = validar_integrador(integrator_id, api_key)
      return render json: { 'code' => -1, 'msg' => 'integrador no valido', 'status' => 400 }, status: 400 if integrador.nil?

      user = User.find_by(username: user_name, grupo_id: integrador.grupo_id)
      return render json: { 'code' => -1, 'msg' => 'usuario no valido', 'status' => 400 }, status: 400 if user.nil?

      session[:usuario_actual] = user
      params[:source] = 'api'
      cuadre_general_por_agentes_externo
    end

    def filter_reporte(reporte, desde, hasta)
      grupo_id = session[:usuario_actual]['grupo_id']
      text_search = params[:only_awards] ? 'premiada = true' : ''

      monto = PropuestasCaballosPuesto.where("created_at between '#{desde} 00:00'::timestamp and '#{hasta} 23:59'::timestamp").where(status: 2, grupo_id: grupo_id).where("#{text_search}").sum(:monto).to_f
      monto += PropuestasCaballosPuesto.where("created_at between '#{desde} 00:00'::timestamp and '#{hasta} 23:59'::timestamp").where(status: 2, grupo_id: grupo_id).where("#{text_search}").sum(:cuanto_gana_completo).to_f
      reporte.map do |rep|
        { name: rep['nombre'], total_match: monto.to_f.round(2), awards: rep['premio_solo'].to_f.round(2), commission: rep['comision'].to_f.round(2) }
      end
    end
    
    def cuadre_general_por_agentes_externo
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @tipo_cruzado = 'Cruzado'
      @nombre_reporte_titulo = 'Agentes'
      @desde = params[:desde].to_time.strftime('%d/%m/%Y')
      @hasta = params[:hasta].to_time.strftime('%d/%m/%Y')
      producto = params[:producto].to_i
      @reporte = []
      estructuras1 = []
      estructuras2 = []
      tipo_user = 0
      @tipo_cruzado = 'Jugado'
      @porcentaje_banca = Grupo.find(session[:usuario_actual]['grupo_id']).porcentaje_banca.to_f

      tipo_user = 3
      buscar_tipo = if session[:usuario_actual]['tipo'] == 'GRP'
                      Cobradore.where(grupo_id: session[:usuario_actual]['grupo_id']).order(:nombre)
                    else
                      Cobradore.where(id: session[:usuario_actual]['cobrador_id']).order(:nombre)
                    end
      buscar_tipo.each do |cob|
        taqs = []
        taqs = UsuariosTaquilla.where(cobrador_id: cob.id).ids
        estructuras = Estructura.where(tipo: 4, tipo_id: taqs).order(:nombre).pluck(:id)
        jugado_bs = 0
        jugado_usd = 0
        ganado_bs = 0
        ganado_usd = 0
        porcentaje_bg_bs = 0
        porcentaje_bg_usd = 0
        case producto
        when 0
          premio = 0
          comision = 0
          monto_otro_grupo = 0
          gano_oc = 0
          perdio_oc = 0
          comision_oc = 0
          reporte1 = CuadreGeneralCaballosPuesto.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte2 = CuadreGeneralCaballosLogro.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte3 = CuadreGeneralDeporte.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte1.each do |rep|
            premio += rep.premio.to_f
            comision += rep.comision.to_f
            monto_otro_grupo += rep.monto_otro_grupo.to_f
            gano_oc += rep.gano_oc.to_f
            perdio_oc += rep.perdio_oc.to_f
            comision_oc += rep.comision_oc.to_f
          end
          reporte2.each do |rep|
            premio += rep.premio.to_f
            comision += rep.comision.to_f
            monto_otro_grupo += rep.monto_otro_grupo.to_f
            gano_oc += rep.gano_oc.to_f
            perdio_oc += rep.perdio_oc.to_f
            comision_oc += rep.comision_oc.to_f
          end
          reporte3.each do |rep|
            premio += rep.premio.to_f
            comision += rep.comision.to_f
            monto_otro_grupo += rep.monto_otro_grupo.to_f
            gano_oc += rep.gano_oc.to_f
            perdio_oc += rep.perdio_oc.to_f
            comision_oc += rep.comision_oc.to_f
          end

          tipo = 'COB'
          @tipo_reporte2url = 'COB'
          venta_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Solicitud de retiro|Ajuste'").where('monto < 0').where(
            usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: [
              1, 2, 3
            ]
          ).sum(:monto_dolar)
          premio_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Retiro rechazado|Recarga de saldo|Ajuste'").where('monto > 0').where(
            usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: [
              1, 2, 3
            ]
          ).sum(:monto_dolar)
          @reporte << { 'id' => cob.id, 'nombre' => cob.nombre, 'venta' => (venta_ext * -1).to_f,
                        'premio' => premio_ext.to_f, 'premio_solo' => premio.to_f, 'gano_oc' => gano_oc.to_f, 'perdio_oc' => perdio_oc.to_f, 'comision' => comision.to_f, 'comision_oc' => comision_oc.to_f, 'monto_otro_grupo' => monto_otro_grupo.to_f, 'tipo' => tipo, 'comision_banca' => cob.comision_banca.to_f }
        when 1
          reporte2 = CuadreGeneralCaballosPuesto.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte2.length.times do |t|
            tipo = 'COB'
            @tipo_reporte2url = 'COB'
            venta_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Solicitud de retiro|Ajuste'").where('monto < 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 1
            ).sum(:monto_dolar)
            premio_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Retiro rechazado|Recarga de saldo|Ajuste'").where('monto > 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 1
            ).sum(:monto_dolar)
            @reporte << { 'id' => cob.id, 'nombre' => cob.nombre, 'venta' => (venta_ext * -1).to_f,
                          'premio' => premio_ext.to_f, 'premio_solo' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'monto_otro_grupo' => reporte2[t].monto_otro_grupo.to_f, 'tipo' => tipo, 'comision_banca' => cob.comision_banca.to_f }
          end
        when 2
          reporte2 = CuadreGeneralCaballosLogro.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte2.length.times do |t|
            tipo = 'COB'
            @tipo_reporte2url = 'COB'
            venta_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Solicitud de retiro|Ajuste'").where('monto < 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 3
            ).sum(:monto_dolar)
            premio_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Retiro rechazado|Recarga de saldo|Ajuste'").where('monto > 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 3
            ).sum(:monto_dolar)
            @reporte << { 'id' => cob.id, 'nombre' => cob.nombre, 'venta' => (venta_ext * -1).to_f,
                          'premio' => premio_ext.to_f, 'premio_solo' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'monto_otro_grupo' => reporte2[t].monto_otro_grupo.to_f, 'tipo' => tipo, 'comision_banca' => cob.comision_banca.to_f }
          end
        when 3
          reporte2 = CuadreGeneralDeporte.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
            estructura_id: estructuras, moneda: 2
          ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
          reporte2.length.times do |t|
            tipo = 'COB'
            @tipo_reporte2url = 'COB'
            venta_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Solicitud de retiro|Ajuste'").where('monto < 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 2
            ).sum(:monto_dolar)
            premio_ext = OperacionesCajero.where.not(tipo_app: 10).where.not("descripcion ~* 'Retiro rechazado|Recarga de saldo|Ajuste'").where('monto > 0').where(
              usuarios_taquilla_id: taqs, created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, tipo_app: 2
            ).sum(:monto_dolar)
            @reporte << { 'id' => cob.id, 'nombre' => cob.nombre, 'venta' => (venta_ext * -1).to_f,
                          'premio' => premio_ext.to_f, 'premio_solo' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'monto_otro_grupo' => reporte2[t].monto_otro_grupo.to_f, 'tipo' => tipo, 'comision_banca' => cob.comision_banca.to_f }
          end
        end
      end

      @reporte = @reporte.group_by { |r| r['id'] }.map do |_, v|
        v.each_with_object(v.shift.dup) do |r, a|
          a['venta'] += r['venta']
          a['premio'] += r['premio']
          a['gano_oc'] += r['gano_oc']
          a['perdio_oc'] += r['perdio_oc']
          a['comision'] += r['comision']
          a['comision_oc'] += r['comision_oc']
          a['monto_otro_grupo'] += r['monto_otro_grupo']
        end
      end
      @reporte = @reporte.reject { |rep| rep['venta'].to_f == 0 }
      return render json: filter_reporte(@reporte, fecha_desde, fecha_hasta), status: 200 if params[:source] == 'api'

      respond_to do |format|
        format.html do
          render partial: 'unica/reportes/general_por_grupo_caballos_externo', layout: false
        end
        format.pdf do
          render pdf: 'cuadre_general', page_size: 'A4', orientation: 'Landscape',
                 template: 'unica/reportes/general_por_grupo_caballos_externo.pdf.erb',
                 font_size: 6,
                 footer: { center: 'Pag: [page] de [topage]' }
        end
        format.xlsx do
          response.headers[
            'Content-Disposition'
          ] = "attachment; filename=cuadre_general_agente_#{@desde}_#{@hasta}.xlsx"
        end
      end
    end

    def cuadre_general_por_agentes_externo_general
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @tipo_cruzado = 'Cruzado'
      @nombre_reporte_titulo = 'Agentes'
      @desde = params[:desde].to_time.strftime('%d/%m/%Y')
      @hasta = params[:hasta].to_time.strftime('%d/%m/%Y')
      @reporte = []
      estructuras1 = []
      estructuras2 = []
      tipo_user = 0
      @tipo_cruzado = 'Jugado'
      case session[:usuario_actual]['tipo']
      when 'ADM'
        estructuras1 = Estructura.where(tipo: 2).order(:nombre).pluck(:id)
        estructuras2 = Estructura.where(tipo: 3,
                                        tipo_id: Grupo.where(intermediario_id: 0).ids).order(:nombre).pluck(:id)
        estructuras = estructuras1 + estructuras2
        buscar_tipo = Intermediario.select(:id, :nombre).all
      when 'INT'
        tipo_user = 2
        estructuras = Estructura.where(tipo: 3,
                                       tipo_id: Grupo.where(intermediario_id: session[:usuario_actual]['intermediario_id']).ids).order(:nombre).pluck(:id)
        buscar_tipo = Grupo.select(:id, :nombre).where(intermediario_id: session[:usuario_actual]['intermediario_id'])
      when 'GRP'
        @tipo_cruzado = 'Jugado'
        tipo_user = 3
        taqs = UsuariosTaquilla.select(:id).where(grupo_id: session[:usuario_actual]['grupo_id']).ids
        #     estructuras = Estructura.where(tipo: 4, tipo_id: taqs).order(:nombre).pluck(:id)
        buscar_tipo = UsuariosTaquilla.select(:id, :nombre).where(id: taqs).order(:nombre)
      when 'COB'
        @tipo_cruzado = 'Jugado'
        tipo_user = 3
        taqs = UsuariosTaquilla.select(:id, :nombre).where(cobrador_id: session[:usuario_actual]['cobrador_id']).ids
        #      estructuras = Estructura.where(tipo: 4, tipo_id: taqs).order(:nombre).pluck(:id)
        buscar_tipo = UsuariosTaquilla.select(:id,
                                              :nombre).where(cobrador_id: session[:usuario_actual]['cobrador_id']).order(:nombre)
      end

      buscar_tipo.each do |cob|
        taqs = []
        ## if cob.usuarios_taquilla_id.present?
        #  taqs = JSON.parse(cob.usuarios_taquilla_id)
        # end
        estructuras = Estructura.where(tipo: 4, tipo_id: cob.id).order(:nombre).pluck(:id)
        jugado_bs = 0
        jugado_usd = 0
        ganado_bs = 0
        ganado_usd = 0
        porcentaje_bg_bs = 0
        porcentaje_bg_usd = 0
        reporte2 = CuadreGeneralCaballo.select('sum(venta) as venta, sum(premio) as premio, sum(gano_oc) as gano_oc,sum(perdio_oc) as perdio_oc, sum(comision) as comision,sum(comision_oc) as comision_oc, sum(monto_otro_grupo) as monto_otro_grupo').where(
          estructura_id: estructuras, moneda: 2
        ).where("created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp")
        reporte2.length.times do |t|
          tipo = 'COB'
          @tipo_reporte2url = 'COB'
          venta_ext = OperacionesCajero.where(usuarios_taquilla_id: cob.id,
                                              created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).where('monto < 0').sum(:monto_dolar)
          premio_ext = OperacionesCajero.where(usuarios_taquilla_id: cob.id,
                                               created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).where('monto > 0').sum(:monto_dolar)
          if (venta_ext.to_f * -1) > 0
            @reporte << { 'id' => cob.id, 'nombre' => cob.nombre, 'venta' => (venta_ext * -1).to_f,
                          'premio' => premio_ext.to_f, 'premio_solo' => reporte2[t].premio.to_f, 'gano_oc' => reporte2[t].gano_oc.to_f, 'perdio_oc' => reporte2[t].perdio_oc.to_f, 'comision' => reporte2[t].comision.to_f, 'comision_oc' => reporte2[t].comision_oc.to_f, 'monto_otro_grupo' => 0, 'tipo' => tipo, 'comision_banca' => 0 }
          end
        end
      end

      @reporte = @reporte.group_by { |r| r['id'] }.map do |_, v|
        v.each_with_object(v.shift.dup) do |r, a|
          a['venta'] += r['venta']
          a['premio'] += r['premio']
          a['gano_oc'] += r['gano_oc']
          a['perdio_oc'] += r['perdio_oc']
          a['comision'] += r['comision']
          a['comision_oc'] += r['comision_oc']
          a['monto_otro_grupo'] += r['monto_otro_grupo']
        end
      end
      respond_to do |format|
        format.html do
          render partial: 'reportes/general_por_grupo_caballos_externo_general', layout: false
        end
        format.pdf do
          render pdf: 'cuadre_general', page_size: 'Letter',
                 template: 'reportes/general_por_grupo_caballos_externo_general.pdf.erb',
                 font_size: 6,
                 footer: { center: 'Pag: [page] de [topage]' }
        end
        format.xlsx do
          response.headers[
            'Content-Disposition'
          ] = "attachment; filename=cuadre_general_agente_#{@desde}_#{@hasta}.xlsx"
        end
      end
    end

    def premios_ingresados_index
      render action: 'premios_ingresados'
    end

    def premios_ingresados
      tipo = 'ADM'
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      hip = params[:hip_id].to_i

      if hip > 0
        @reporte = PremiosIngresado.where(
          created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, hipodromo_id: hip
        ).order(:id)
      else
        @reporte = PremiosIngresado.where(created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:id)
      end
      render partial: 'reportes/cuerpo_premios', layout: false
    end

    def premios_ingresados_deportes
      render action: 'premios_ingresados_deportes'
    end

    def premios_ingresados_ingresados_consulta
      tipo = 'ADM'
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      juegos = params[:juego_id].to_i

      if juegos > 0
        @reporte = PremiosIngresadosDeporte.where(
          created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, juego_id: juegos
        ).order(:id)
      else
        @reporte = PremiosIngresadosDeporte.where(created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:id)
      end
      render partial: 'reportes/cuerpo_premios_deportes', layout: false
    end

    def posttime
      render action: 'posttime'
    end

    def posttime_consulta
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      hid = params[:hid].to_i
      if hid > 0
        hips = Hipodromo.find(hid)
        ids = hips.jornada.where(fecha: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).last.carrera.pluck(:id)
        @reporte = Postime.where(created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day,
                                 carrera_id: ids).order(:id)
      else
        @reporte = Postime.where(created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:id)
      end
      render partial: 'reportes/cuerpo_posttime', layout: false
    end

    def solicitudes
      render action: 'solicitudes'
    end

    def estados(id)
      case id
      when 1
        'Pendiente'
      when 2
        'Procesado'
      when 3
        'Rechazado'
      end
    end

    def solicitudes_filtradas
      tipo = params[:tipo].to_i
      estado = params[:estado].to_i
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      ids = UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).ids
      todas = []
      case tipo
      when 0
        if estado == 0
          soli1 = SolicitudRecarga.where(usuarios_taquilla_id: ids,
                                         created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day)
          soli2 = SolicitudRetiro.where(usuarios_taquilla_id: ids,
                                        created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day)
        else
          soli1 = SolicitudRecarga.where(usuarios_taquilla_id: ids,
                                         created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, status: estado)
          soli2 = SolicitudRetiro.where(usuarios_taquilla_id: ids,
                                        created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, status: estado)
        end
        todas = []
        soli1.each do |sol|
          todas << { 'taq_id' => sol.usuarios_taquilla_id, 'nombre' => sol.nombre,
                     'cuenta_id' => sol.cuentas_banca_id, 'numero_cuenta' => sol.cuentas_banca.numero_cuenta, 'tipo' => 'Recarga', 'monto' => sol.monto, 'fecha' => sol.created_at.strftime('%d/%m/%Y %I:%M %p'), 'fecha_p' => sol.updated_at.strftime('%d/%m/%Y %I:%M %p'), 'status' => estados(sol.status), 'tipo2' => 'Cuenta Banca', 'moneda' => sol.cuentas_banca.moneda }
        end
        soli2.each do |sol|
          todas << { 'taq_id' => sol.usuarios_taquilla_id, 'nombre' => sol.nombre,
                     'cuenta_id' => sol.cuentas_cliente_id, 'numero_cuenta' => sol.cuentas_cliente.numero_cuenta, 'tipo' => 'Pagos', 'monto' => sol.monto, 'fecha' => sol.created_at.strftime('%d/%m/%Y %I:%M %p'), 'fecha_p' => sol.updated_at.strftime('%d/%m/%Y %I:%M %p'), 'status' => estados(sol.status), 'tipo2' => 'Cuenta Cliente', 'moneda' => sol.cuentas_cliente.moneda }
        end
        @solicitudes = todas.sort_by { |hsh| hsh['fecha'] }
        render partial: 'reportes/estado', layout: false
      when 1
        if estado == 0
          soli1 = SolicitudRecarga.where(usuarios_taquilla_id: ids,
                                         created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:created_at)
        else
          soli1 = SolicitudRecarga.where(usuarios_taquilla_id: ids,
                                         created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, status: estado).order(:created_at)
        end
        soli1.each do |sol|
          todas << { 'taq_id' => sol.usuarios_taquilla_id, 'nombre' => sol.nombre,
                     'cuenta_id' => sol.cuentas_banca_id, 'numero_cuenta' => sol.cuentas_banca.numero_cuenta, 'tipo' => 'Recarga', 'monto' => sol.monto, 'fecha' => sol.created_at.strftime('%d/%m/%Y %I:%M %p'), 'status' => estados(sol.status), 'tipo2' => 'Cuenta Banca', 'moneda' => sol.cuentas_banca.moneda }
        end
        @solicitudes = todas.sort_by { |hsh| hsh['fecha'] }
        render partial: 'reportes/estado', layout: false
      when 2
        if estado == 0
          soli2 = SolicitudRetiro.where(usuarios_taquilla_id: ids,
                                        created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:created_at)
        else
          soli2 = SolicitudRetiro.where(usuarios_taquilla_id: ids,
                                        created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day, status: estado).order(:created_at)
        end
        soli2.each do |sol|
          todas << { 'taq_id' => sol.usuarios_taquilla_id, 'nombre' => sol.nombre,
                     'cuenta_id' => sol.cuentas_cliente_id, 'numero_cuenta' => sol.cuentas_cliente.numero_cuenta, 'tipo' => 'Retiro', 'monto' => sol.monto, 'fecha' => sol.created_at.strftime('%d/%m/%Y %I:%M %p'), 'status' => estados(sol.status), 'tipo2' => 'Cuenta Cliente', 'moneda' => sol.cuentas_cliente.moneda }
        end
        @solicitudes = todas.sort_by { |hsh| hsh['fecha'] }
        render partial: 'reportes/estado', layout: false
      end
    end

    def relacion_tickets
      # if session[:usuario_actual]['tipo'] == 'COB'
      #   @taquillas = UsuariosTaquilla.where(id: JSON.parse(Cobradore.find(session[:usuario_actual]['cobrador_id'].to_i).usuarios_taquilla_id)).order(:alias)
      # else
      #   if session[:usuario_actual]['tipo'] == 'ADM'
      #     @taquillas = UsuariosTaquilla.all.order(:alias)
      #   else
      #     @taquillas = UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:alias)
      #   end
      # end
    end

    def buscar_tickets_detalle
      t_id = params[:t_id].to_i
      ticket = TicketsDetalle.find_by(id: t_id)
      @user_taq = ticket.ticket.usuarios_taquilla
      id_usuario = @user_taq.id.to_i
      @valor_dolar = @user_taq.moneda_default_dolar.to_f
      @simbolo = @user_taq.simbolo_moneda_default
      @datos = ticket.propuestas
      render partial: 'detalle_tickets_completo'
    end

    def find_ticket_id(t_id)
      url = URI.parse(BaseUrl.last.gticket)
      parameters = { "gticket" => t_id }
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url.path, { 'Content-Type' => 'application/json' })
      if ENV['gtickets_headers'] == 'SI'
        request['X-API-Key'] = ENV['gtickets_api_key']  
      end
      request.body = parameters.to_json
      response = http.request(request)
      respuesta_json = []
      transaction_id = if response.is_a?(Net::HTTPOK)
                         respuesta_json = JSON.parse(response.body)
                         respuesta_json["detalle"][0]["transactionId"]
                       else
                         [nil, respuesta_json]
                       end
Rails.logger.info "Respuesta de GTicket: #{respuesta_json.inspect}"                       

      [transaction_id, respuesta_json]
    end

    def relacion_tickets_detalle
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      tipo = params[:tipo].to_i
      taquilla_id = params[:taquilla_id].to_i
      if tipo == 1
        @datos = TicketsDetalle.tickets_by_client(taquilla_id, fecha_desde, fecha_hasta)
        @gticket = @datos.gticket
        render partial: 'detalle_tickets'
      else
        t_id, datos_gticket = tipo == 2 ? params[:t_id].to_i : find_ticket_id(params[:t_id])
        ticket = TicketsDetalle.find_by(id: t_id)
        @gticket = ticket.gticket
        if ticket.present?
          @user_taq = ticket.ticket.usuarios_taquilla
          id_usuario = @user_taq.id.to_i
          @valor_dolar = @user_taq.moneda_default_dolar.to_f
          @simbolo = @user_taq.simbolo_moneda_default
          if session[:usuario_actual]['tipo'] == 'COB'
            if @user_taq.cobrador_id.to_i != session[:usuario_actual]['cobrador_id'].to_i
              render json: { 'status' => 'faild', 'mensaje' => 'Ticket no corresponde al usuario que consulta.' },
                     status: 400 and return
            end
          else
            if session[:usuario_actual]['tipo'] != 'ADM'
              if @user_taq.grupo_id.to_i != session[:usuario_actual]['grupo_id'].to_i
                render json: { 'status' => 'faild', 'mensaje' => 'Ticket no corresponde al usuario que consulta.' },
                       status: 400 and return
              end
            end
          end
          @datos = ticket.propuesta_caballos_puesto_id > 0 ? ticket.propuestas : []
          render partial: 'detalle_tickets_completo', locals: { datos_gticket: datos_gticket }
        elsif tipo == 3
          @user_taq = []
          @datos = []
          render partial: 'detalle_tickets_completo', locals: { datos_gticket: datos_gticket }
        else
          render json: { 'status' => 'faild', 'mensaje' => 'No existe ticket con el numero ingresado.' }, status: 400
        end
      end
    end

    def movimientos
      if session[:usuario_actual]['tipo'] == 'COB'
        @taquillas = UsuariosTaquilla.where(id: JSON.parse(Cobradore.find(session[:usuario_actual]['cobrador_id'].to_i).usuarios_taquilla_id)).order(:alias)
      else
        @taquillas = UsuariosTaquilla.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).order(:alias)
      end
      render action: 'movimientos'
    end

    def movimientos_taquilla
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      hip = params[:hip_id].to_i
      id = params[:taquilla_id].to_i
      @movimientos = OperacionesCajero.where(usuarios_taquilla_id: id,
                                             created_at: fecha_desde.to_time.beginning_of_day..fecha_hasta.to_time.end_of_day).order(:id)
      render partial: 'unica/reportes/movimientos_taq', layout: false
    end

    def cuadre_general_grupo
      render action: 'cuadre_general_grupo'
    end

    def cuadre_general_grupo2
      tipo = 'ADM'
      fecha_desde = params[:desde]
      fecha_hasta = params[:hasta]
      @reporte = ActiveRecord::Base.connection.execute("select id, nombre,(select sum(monto) * -1 as monto from operaciones_cajeros where moneda = 1 and tipo in (1,2) and usuarios_taquilla_id = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp) as jugado_bs ,(select sum(monto) * -1 as monto from operaciones_cajeros where tipo in (1,2) and usuarios_taquilla_id = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2) as jugado_usd, (select sum(monto_pagado_completo) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp) as ganado_bs, (select sum(monto_pagado_completo) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2 ) as ganado_usd, (select sum(monto_pagado_completo - monto_pagado) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 1 ) as comision_gt_bs, (select sum(monto_pagado_completo - monto_pagado) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2 ) as comision_gt_usd,(select sum((monto_pagado_completo * premiacions.porcentaje_bg)/100) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 1 ) as comision_bg_bs,(select sum((monto_pagado_completo * premiacions.porcentaje_bg)/100) from premiacions where repremiado = false and id_gana = usuarios_taquillas.id and created_at between '#{fecha_desde} 00:00'::timestamp and '#{fecha_hasta} 23:59'::timestamp and moneda = 2 ) as comision_bg_usd from usuarios_taquillas where grupo_id = #{session[:usuario_actual]['grupo_id'].to_i} order by nombre")
      render partial: 'reportes/general_por_grupo2', layout: false
    end

    def historial_tasa
      @monedas = Moneda.where(id: FactorCambio.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i).pluck(:moneda_id))
    end

    def historial_tasas
      moneda = params[:moneda].to_i
      desde = params[:desde]
      hasta = params[:hasta]
      if moneda > 0
        @historial = HistorialTasa.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i, moneda_id: moneda,
                                         created_at: desde.to_time.beginning_of_day..hasta.to_time.end_of_day)
      else
        @historial = HistorialTasa.where(grupo_id: session[:usuario_actual]['grupo_id'].to_i,
                                         created_at: desde.to_time.beginning_of_day..hasta.to_time.end_of_day)
      end

      render partial: 'reportes/historial_tasa', layout: false
    end

    def carreras_cerradas; end

    def carreras_cerradas_fecha
      desde = params[:desde]
      hasta = params[:hasta]
      hip = params[:hipodromo_id].to_i
      if hip > 0
        jors = Jornada.where(hipodromo_id: hip, fecha: desde.to_time.beginning_of_day..hasta.to_time.end_of_day).ids
        @carreras = Carrera.where(jornada_id: jors, activo: false,
                                  created_at: desde.to_time.beginning_of_day..hasta.to_time.end_of_day).order(:id)
      else
        # jor = Jornada.where(hipodromo_id: Hipodromo.where(activo: true).ids)
        @carreras = Carrera.where(activo: false,
                                  created_at: desde.to_time.beginning_of_day..hasta.to_time.end_of_day).order(:id)
      end
      render partial: 'reportes/carreras_cerradas', layout: false
    end

    def pases_cajero_externo; end

    def buscar_carreras_cerradas_fecha
      hip = Hipodromo.find(params[:hipodromo_id]).jornada.where(fecha: params[:desde].to_time.all_day)
      @carreras = []
      @carreras = hip.last.carrera.order(:id, :numero_carrera) if hip.present?
      render partial: 'carreras_dia'
    end

    def consultar_pase_cajero_externo
      fecha = params[:desde].to_time.all_day
      carrera = params[:carrera].to_i
      integrador = params[:integrador].to_i
      @datos = RetornosBloqueApi.where(carrera_id: carrera, integrador_id: integrador, created_at: fecha)

      render partial: 'cuerpo_reporte_cajero'
    end

    def cuadre_mensual
      @fecha_desde = Time.now.beginning_of_month.strftime('%d/%m/%Y')
      @fecha_hasta = Time.now.end_of_month.strftime('%d/%m/%Y')
    end

    def cuadre_mensual_grupo
      @fecha = params[:desde].split('-')
      month = @fecha[1].to_i
      year = @fecha[0].to_i
      @reporte = PropuestasCaballosPuesto.calcular_ganancia_y_porcentaje_detallado_monedas(month, year)
      render partial: 'unica/reportes/cuerpo_cuadre_mensual_grupo', layout: false
    end

    def cuadre_paginas_grupo
      @reportes = PropuestasCaballosPuesto.cuadre_paginas(params[:desde], params[:hasta])
      render partial: 'unica/reportes/cuerpo_cuadre_paginas_grupo', layout: false
    end
  end
end
