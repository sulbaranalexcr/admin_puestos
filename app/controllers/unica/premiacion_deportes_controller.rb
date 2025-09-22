module Unica
  class PremiacionDeportesController < ApplicationController
    skip_before_action :verify_authenticity_token
    #    before_action :check_user_auth, only: [:show, :index]
    #    before_action :seguridad_cuentas, only: [:index]
    include ApplicationHelper
    include PremiarHelper

    def indexs
      @deportes = []
    end

    def buscar_deportes
      fecha = params[:fecha].to_time.all_day
      @deportes = Juego.where(juego_id: JornadaDeporte.where(fecha: fecha).pluck(:juego_id)).order(:nombre)
      render partial: "/deportes/div_deportes"
    end

    def buscar_ligas
      fecha = params[:fecha].to_time.all_day
      @ligas = Liga.where(juego_id: params[:id], liga_id: Match.where(juego_id: params[:id], local: fecha).pluck(:liga_id), activo: true).order(:nombre)
      render partial: "/deportes/div_ligas"
    end

    def buscar_matchs
      fecha = params[:fecha].to_time.all_day
      @matchs = Match.where(juego_id: params[:deporte_id], liga_id: params[:liga_id], local: fecha).order(:local, :nombre)
      render partial: "/deportes/div_matchs"
    end

    def buscar_juego
      fecha = params[:fecha].to_time.all_day
      @juegos = Match.find_by(id: params[:id])
      @tipo_fin = []
      case @juegos.juego_id.to_i
      when 12
        @tipo_fin = [1, 3]
      when 4
        @tipo_fin = [1, 2, 3]
      else
        @tipo_fin = [1, 2, 3]
      end

      if @juegos.present?
        equipos = JSON.parse(@juegos.data)
        if @juegos.juego_id.to_i == 12
          id1 = equipos['money_line']['c'][1]['i']
          id2 = equipos['money_line']['c'][2]['i']
          nom1 = equipos['money_line']['c'][1]['t']
          nom2 = equipos['money_line']['c'][2]['t']
        else
          id1 = equipos['money_line']['c'][0]['i']
          id2 = equipos['money_line']['c'][1]['i']
          nom1 = equipos['money_line']['c'][0]['t']
          nom2 = equipos['money_line']['c'][1]['t']
        end

        @equipo1 = { 'id' => id1, 'nom' => nom1 }
        @equipo2 = { 'id' => id2, 'nom' => nom2 }

        prem = PremiosIngresadosDeporte.where(juego_id: @juegos.juego_id, match_id: @juegos.id, created_at: fecha)
        if prem.present?
          @premio_ingresado = JSON.parse(prem.last.resultado)
        else
          @premio_ingresado = []
        end

        render partial: "/unica/premiacion_deportes/div_juegos"
      else
        render json: { "msg" => "No se encontro el match." }, status: 400
      end
    end

    def repremiar(deporte_id, match_id, fecha)
      matchs = Match.where(juego_id: deporte_id, id: match_id).last
      CuadreGeneralDeporte.where(juego_id: deporte_id, match_id: match_id, created_at: fecha).delete_all
      prembus_rep = PremiosIngresadosDeporte.where(juego_id: deporte_id, match_id: match_id, created_at: fecha)
      if prembus_rep.present?
        prembus_rep.update_all(repremio: true, updated_at: DateTime.now)
      end

      match_bus = JuegosPremiado.where(match_id: @match_id, activo: true)
      if match_bus.present?
        match_bus.each { |jue_bus|
          opcaj = OperacionesCajero.find(jue_bus.operaciones_cajero_id)
          monto = opcaj.monto
          desc = "Reverso error de premiacion Juego: #{matchs.nombre}"
          utsal = UsuariosTaquilla.find(jue_bus.usuarios_taquilla_id)

          if utsal.usa_cajero_externo.blank? && utsal.saldo_usd.to_f >= monto
            OperacionesCajero.create(usuarios_taquilla_id: jue_bus.usuarios_taquilla_id, descripcion: desc, monto: (monto * -1), status: 0, moneda: 2, tipo: 4, tipo_app: 2)
          end
          jue_bus.update(activo: false)
        }
        PropuestasDeporte.where(match_id: @match_id).where("status2 > 7").update_all(status2: 2, status: 2, premiada: false, updated_at: DateTime.now)
      end
    end

    def premiar_juego
      buscar_match = Match.find_by(id: params[:id_match])
      buscar_match.update(activo: false)
      fecha = params[:fecha]
      match_id = params[:match_id].to_i
      @match_id = params[:match_id].to_i
      deporte_id = params[:deporte_id].to_i

      liga_id = params[:liga_id].to_i
      @premios_array_cajero = []
      @retirar_array_cajero = []
      @cierrec_array_cajero = []
      @nojuega_array_cajero = []
      @usuarios_interno_ganan = []
      ids_dia = PropuestasDeporte.where(match_id: match_id).map { |a| [a.id_juega] + [a.id_banquea] }.join(",").split(",").uniq.map! { |e| e.to_i }.reject { |k| k == 0 }
      if ids_dia.present?
        ids_dia = ids_dia.uniq
      else
        ids_dia = []
      end

      @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
      @ids_cajero_externop =  ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json

      fecha_hora = (fecha + " " + Time.now.strftime("%H:%M")).to_time
      arreglo = []
      empates = Hash.new
      detalle = Hash.new
      if params[:premia_api].present?
        @id_quien_premia = 1
      else
        @id_quien_premia = session[:usuario_actual]["id"]
      end

      esrepremio = false
      eq1_id = params[:eq1_id].to_i
      eq2_id = params[:eq2_id].to_i
      iq3_id = [eq1_id, eq2_id]
      es_empate = false
      eq1_resul = params[:eq1_resul].to_i
      eq2_resul = params[:eq2_resul].to_i
      nombre_eq1 = params[:eq1_nombre]
      nombre_eq2 = params[:eq2_nombre]
      equipo_ganador = eq1_resul > eq2_resul ? eq1_id : eq2_id
      es_empate = (eq1_resul == eq2_resul)
      finalizado = params[:finalizado].to_i

      #    begin
      ActiveRecord::Base.transaction do
        if PremiosIngresadosDeporte.where(match_id: match_id).count > 0
          repremiar(deporte_id, match_id, fecha)
          esrepremio = true
        end

        if buscar_match.activo
          buscar_match.update(activo: false)
        end
        ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "CLOSE_MATCH", "match_id" => [match_id], "data_menu" => menu_deportes_helper(deporte_id), "deporte_id" => deporte_id }}

        prupuestas = PropuestasDeporte.where(match_id: match_id, activa: true, status: 1)
        if prupuestas.present?
          updates = prupuestas.update_all(activa: false, status: 4, status2: 7, premiada: true, updated_at: DateTime.now)
          prupuestas.each { |prop|
            if prop.id_propone == prop.id_juega
              tra_id = prop.tickets_detalle_id_juega
              ref_id = prop.reference_id_juega
            else
              tra_id = prop.tickets_detalle_id_banquea
              ref_id = prop.reference_id_banquea
            end
            descripcion = "Reverso/No cruzada #{prop.texto_jugada}"
            OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion, monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 2)
            busca_user = buscar_cliente_cajero(prop.id_propone)
            if busca_user != "0"
              set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, "Devolucion por cierre no cruzada")
            end
          }
        end

        datos_equipos = { "eq1" => { "id" => eq1_id, "nombre" => nombre_eq1, "resultado" => eq1_resul }, "eq2" => { "id" => eq2_id, "nombre" => nombre_eq2, "resultado" => eq2_resul } }
        resultado = { "nombre" => buscar_match.nombre, "resultado" => datos_equipos, "empate" => es_empate, "finalizado" => finalizado }

        esrepremio = false
        @preming = PremiosIngresadosDeporte.create(usuario_premia: session[:usuario_actual]["id"], juego_id: deporte_id, liga_id: liga_id, match_id: match_id, resultado: resultado.to_json, repremio: false, created_at: params[:fecha].to_time)

        if finalizado == 1 or finalizado == 2
          premiar_money_line(deporte_id, match_id, equipo_ganador, iq3_id, es_empate, fecha_hora)
          pagar_perdedor_logros(match_id, fecha_hora, 1)
        end
        if finalizado == 1
          if deporte_id != 12
            premiar_run_line(deporte_id, match_id, es_empate, fecha_hora, eq1_id, eq2_id, eq1_resul, eq2_resul)
            pagar_perdedor_logros(match_id, fecha_hora, 2)
          end
          premiar_alta_baja(deporte_id, match_id, es_empate, fecha_hora, eq1_id, eq2_id, eq1_resul, eq2_resul)
          pagar_perdedor_logros(match_id, fecha_hora, 3)
        elsif finalizado == 2
          detalle = "Juego Incompleto Valido"
          enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: [2,3])
          devolver_completo(enjuego, 14, detalle, 5)
        elsif finalizado == 3
          detalle = "Juego No Valido"
          enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: [1,2,3])
          devolver_completo(enjuego, 14, detalle, 5)
        end

        if @cierrec_array_cajero.length > 0
          PremiacionDeportesApiJob.perform_async @cierrec_array_cajero, liga_id, match_id, 4
        end
        if @retirar_array_cajero.length > 0
          PremiacionDeportesApiJob.perform_async @retirar_array_cajero, liga_id, match_id, 3
        end
        if @nojuega_array_cajero.length > 0
          PremiacionDeportesApiJob.perform_async @nojuega_array_cajero, liga_id, match_id, 5
        end
        if @premios_array_cajero.length > 0
          PremiacionDeportesApiJob.perform_async @premios_array_cajero, liga_id, match_id, 1
        end
        #
        #     Llenar tabla cuadre_general

        if @usuarios_interno_ganan.length > 0
          # saldos_enviar = UsuariosTaquilla.where(id: @usuarios_interno_ganan).pluck(:id, :saldo_usd)
          # ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_SALDOS_PREMIOS", "data" => saldos_enviar }}
        end
        generar_reportes_deporte(deporte_id, match_id, ids_dia, fecha_hora)

      end
      #   rescue
      #   end
    end

    def premiar_money_line(deporte_id, match_id, id_ganador, iq3_id, es_empate, fecha_hora)
      if es_empate
        if deporte_id == 12
          enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: 1).where.not(equipo_id: iq3_id)
          enjuego.each { |enj|
            gana_completo_logros(enj, fecha_hora)
          }
        else
          enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: 1)
          enjuego.each { |enj|
            id_quien_propone = enj.id_propone
            id_quien_toma = (enj.id_propone == enj.id_juega) ? enj.id_banquea : enj.id_juega
            monto_propone = enj.monto
            if enj.id_propone == enj.id_juega
              detalle_tipo_juego = "Jugo"
              detalle_tipo_juego2 = "Banqueo"
            else
              detalle_tipo_juego = "Banqueo"
              detalle_tipo_juego2 = "Jugo"
            end
            monto_toma = enj.cuanto_gana_completo
            reference_id_propone = (enj.id_propone == enj.id_juega) ? enj.reference_id_juega : enj.reference_id_banquea
            reference_id_toma = (enj.id_propone == enj.id_juega) ? enj.reference_id_banquea : enj.reference_id_juega
            tickets_detalle_id_propone = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
            tickets_detalle_id_toma = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
            descripcion = "Dev/Empate #{detalle_tipo_juego} #{enj.texto_jugada}"
            actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)

            if enj.cruzo_igual_accion
              if enj.accion_id == 1
                detalle_tipo_juego2 = "Jugo"
              else
                detalle_tipo_juego2 = "Banqueo"
              end
              texto_toma = enj.texto_igual_condicion
            else
              texto_toma = enj.texto_jugada
            end
            descripcion2 = "Dev/Empate #{detalle_tipo_juego2} #{texto_toma}"
            actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
            enj.update(activa: false, status: 4, status2: 10, premiada: true)
            busca_user = buscar_cliente_cajero(enj.id_propone)
            if busca_user != "0"
              set_envios_api(1, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f, "Devolucion/Empate")
            end
            busca_user = buscar_cliente_cajero(id_quien_toma)
            if busca_user != "0"
              set_envios_api(1, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f, "Devolucion/Empate")
            end
          }
        end
      else
        enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, equipo_id: id_ganador, tipo_apuesta: 1)
        enjuego.each do |enj|
          gana_completo_logros(enj, fecha_hora)
        end
      end
    end

    def devolver_completo(enjuego, estado, detalle, tipo_envio) ### retiro y ni entra en juego
      enjuego.each { |enj|
        id_quien_propone = enj.id_propone
        id_quien_toma = (enj.id_propone == enj.id_juega) ? enj.id_banquea : enj.id_juega
        monto_propone = enj.monto
        if enj.id_propone == enj.id_juega
          detalle_tipo_juego = "Jugo"
          detalle_tipo_juego2 = "Banqueo"
        else
          detalle_tipo_juego = "Banqueo"
          detalle_tipo_juego2 = "Jugo"
        end
        monto_toma = enj.cuanto_gana_completo
        reference_id_propone = (enj.id_propone == enj.id_juega) ? enj.reference_id_juega : enj.reference_id_banquea
        reference_id_toma = (enj.id_propone == enj.id_juega) ? enj.reference_id_banquea : enj.reference_id_juega
        tickets_detalle_id_propone = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
        tickets_detalle_id_toma = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
        descripcion = "#{detalle} #{detalle_tipo_juego} #{enj.texto_jugada}"
        actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)

        if enj.cruzo_igual_accion
          if enj.accion_id == 1
            detalle_tipo_juego2 = "Jugo"
          else
            detalle_tipo_juego2 = "Banqueo"
          end
          texto_toma = enj.texto_igual_condicion
        else
          texto_toma = enj.texto_jugada
        end
        descripcion2 = "#{detalle} #{detalle_tipo_juego2} #{texto_toma}"
        actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
        enj.update(activa: false, status: 4, status2: estado, premiada: true)
        busca_user = buscar_cliente_cajero(enj.id_propone)
        if busca_user != "0"
          set_envios_api(tipo_envio, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f, detalle)
        end
        busca_user = buscar_cliente_cajero(id_quien_toma)
        if busca_user != "0"
          set_envios_api(tipo_envio, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f, detalle)
        end
      }
    end

    def devolver_completo_ind(enj, detalle, tipo_envio) ### retiro y ni entra en juego
      id_quien_propone = enj.id_propone
      id_quien_toma = (enj.id_propone == enj.id_juega) ? enj.id_banquea : enj.id_juega
      monto_propone = enj.monto
      if enj.id_propone == enj.id_juega
        detalle_tipo_juego = "Jugo"
        detalle_tipo_juego2 = "Banqueo"
      else
        detalle_tipo_juego = "Banqueo"
        detalle_tipo_juego2 = "Jugo"
      end
      monto_toma = enj.cuanto_gana_completo
      reference_id_propone = (enj.id_propone == enj.id_juega) ? enj.reference_id_juega : enj.reference_id_banquea
      reference_id_toma = (enj.id_propone == enj.id_juega) ? enj.reference_id_banquea : enj.reference_id_juega
      tickets_detalle_id_propone = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
      tickets_detalle_id_toma = (enj.id_propone == enj.id_juega) ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
      descripcion = "#{detalle} #{detalle_tipo_juego} #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)

      if enj.cruzo_igual_accion
        if enj.accion_id == 1
          detalle_tipo_juego2 = "Jugo"
        else
          detalle_tipo_juego2 = "Banqueo"
        end
        texto_toma = enj.texto_igual_condicion
      else
        texto_toma = enj.texto_jugada
      end
      descripcion2 = "#{detalle} #{detalle_tipo_juego2} #{texto_toma}"
      actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
      enj.update(activa: false, status: 4, status2: 7, premiada: true)
      busca_user = buscar_cliente_cajero(enj.id_propone)
      if busca_user != "0"
        set_envios_api(tipo_envio, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f, detalle)
      end
      busca_user = buscar_cliente_cajero(id_quien_toma)
      if busca_user != "0"
        set_envios_api(tipo_envio, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f, detalle)
      end
    end

    def pagar_perdedor_logros(match_id, fecha_hora, tipo)
      enjuego = PropuestasDeporte.where(status: 2, match_id: match_id, premiada: false, tipo_apuesta: tipo)
      enjuego.each { |enj|
        pierde_completo_ind(enj, fecha_hora)
      }
    end

    def pierde_completo_ind(enj, fecha_hora)
      id_quien_gana = enj.id_banquea
      monto_primario = enj.id_banquea.to_i == enj.id_propone.to_i ? enj.monto.to_f : enj.cuanto_gana_completo.to_f
      monto_secundario = enj.id_banquea.to_i == enj.id_propone.to_i ? enj.cuanto_gana.to_f : enj.cuanto_pierde.to_f
      cuanto_gana = monto_primario + monto_secundario
      monto_reporte = enj.monto.to_f

      if enj.cruzo_igual_accion
        if enj.accion_id == 1
          detalle_tipo_juego2 = "Jugo"
        else
          detalle_tipo_juego2 = "Banqueo"
        end
        texto_toma = enj.texto_igual_condicion
      else
        detalle_tipo_juego2 = "Banqueo"
        texto_toma = enj.texto_jugada
      end

      descripcion = "Gano #{detalle_tipo_juego2} #{texto_toma}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_gana.to_f, 'Gano')
      end
      enj.update(activa: false, status2: 8, id_gana: id_quien_gana, premiada: true)
      PremiacionDeporte.create(moneda: 2, match_id: enj.match_id,
                               id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                               monto_pagado_completo: monto_reporte, created_at: fecha_hora)
    end

    def gana_completo_logros(enj, fecha_hora)
      id_quien_gana = enj.id_juega
      monto_primario = enj.id_juega.to_i == enj.id_propone.to_i ? enj.monto.to_f : enj.cuanto_gana_completo.to_f
      monto_secundario = enj.id_juega.to_i == enj.id_propone.to_i ? enj.cuanto_gana.to_f : enj.cuanto_pierde.to_f
      cuanto_gana = monto_primario + monto_secundario

      descripcion = "Gano #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      enj.update(activa: false, status: 2, status2: 8, id_gana: id_quien_gana, premiada: true)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_gana.to_f, "Gano #{enj.texto_jugada}")
      end
      PremiacionDeporte.create(moneda: 2, match_id: enj.match_id, id_quien_juega: enj.id_juega,
                               id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana, monto_pagado_completo: enj.cuanto_gana_completo.to_f, created_at: fecha_hora)
    end

    def premiar_run_line(deporte_id, match_id, es_empate, fecha_hora, eq1_id, eq2_id, eq1_resul, eq2_resul)
      enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: 2)
      enjuego.each do |enj|
        if enj.equipo_id.to_i == eq1_id.to_i
          if eq1_resul + enj.carreras_dadas > eq2_resul
            gana_completo_logros(enj, fecha_hora)
          elsif (eq1_resul + enj.carreras_dadas) != eq2_resul
            pierde_completo_ind(enj, fecha_hora)
          else
            devolver_completo_ind(enj, "Devolucion/Empate", 1)
          end
        else
          if eq2_resul + enj.carreras_dadas > eq1_resul
            gana_completo_logros(enj, fecha_hora)
          elsif (eq2_resul + enj.carreras_dadas) != eq1_resul
            pierde_completo_ind(enj, fecha_hora)
          else
            devolver_completo_ind(enj, "Devolucion/Empate", 1)
          end
        end
      end
    end

    def premiar_alta_baja(deporte_id, match_id, es_empate, fecha_hora, eq1_id, eq2_id, eq1_resul, eq2_resul)
      enjuego = PropuestasDeporte.where(match_id: match_id, status: 2, premiada: false, tipo_apuesta: 3)
      enjuego.each do |enj|
        if enj.tipo_altabaja == 1
          if (eq1_resul + eq2_resul) > enj.alta_baja
            gana_completo_logros(enj, fecha_hora)
          elsif (eq1_resul + eq2_resul) != enj.alta_baja
            pierde_completo_ind(enj, fecha_hora)
          else
            devolver_completo_ind(enj, "Devolucion/Empate", 1)
          end
        else
          if (eq1_resul + eq2_resul) < enj.alta_baja
            gana_completo_logros(enj, fecha_hora)
          elsif (eq1_resul + eq2_resul) != enj.alta_baja
            pierde_completo_ind(enj, fecha_hora)
          else
            devolver_completo_ind(enj, "Devolucion/Empate", 1)
          end
        end
      end
    end

    private

    def actualizar_saldos(producto, usuario_id, descripcion, monto, moneda, enj_id, tipo = 3)
      monto_t = monto_local(usuario_id, monto)
      opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto_t, status: 0, moneda: 2, tipo: 3, tipo_app: 2)
      JuegosPremiado.create(operaciones_cajero_id: opcaj.id, match_id: @match_id, usuarios_taquilla_id: usuario_id, propuestas_deporte_id: enj_id, activo: true, status: 1)
    end

    # enjuego = Enjuego.where(created_at: fecha.to_time.all_da

  end
end
