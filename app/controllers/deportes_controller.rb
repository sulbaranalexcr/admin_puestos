class DeportesController < ApplicationController
  skip_before_action :verify_authenticity_token
  # before_action :check_user_auth, only: [:show, :index]
  # before_action :seguridad_cuentas, only: [:index]


  def premiar
    @deportes = []
    render action: "premiar"
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
     @matchs = Match.where(juego_id: params[:deporte_id], liga_id: params[:liga_id], local: fecha).order(:nombre)
     render partial: "/deportes/div_matchs"
  end


   def buscar_juego
     fecha = params[:fecha].to_time.all_day
     @juegos = Match.find_by(id: params[:id])
     @tipo_fin = []
     case @juegos.juego_id.to_i
     when 12
       @tipo_fin = [1,3]
     when 4
       @tipo_fin = [1,2,3]
     else
       @tipo_fin = [1,2,3]
     end

     if @juegos.present?
        equipos = JSON.parse(@juegos.data)
        if @juegos.juego_id.to_i == 12
          id1 = equipos['money_line']['c'][1]['i']
          id2 = equipos['money_line']['c'][2]['i']
          nom1 = equipos['money_line']['c'][1]['t']
          nom2 =equipos['money_line']['c'][2]['t']
        else
          id1 = equipos['money_line']['c'][0]['i']
          id2 = equipos['money_line']['c'][1]['i']
          nom1 = equipos['money_line']['c'][0]['t']
          nom2 =equipos['money_line']['c'][1]['t']
        end

         @equipo1 = {"id" => id1, "nom" => nom1}
         @equipo2 = {"id" => id2, "nom" => nom2}

          prem = PremiosIngresadosDeporte.where(juego_id: @juegos.juego_id, match_id: @juegos.id, created_at: fecha)
          if prem.present?
             @premio_ingresado = JSON.parse(prem.last.resultado)
          else
             @premio_ingresado = []
          end

         render partial: "/deportes/div_juegos"
     else
        render json: {"msg" => "No se encontro el match."}, status: 400
     end
  end


  def devolver_apuestas_money_line(deporte_id,liga_id,match_id,nombre)
    ActiveRecord::Base.transaction do
        propuestas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 1, status: 1, activa: true)
        if propuestas.present?
           propuestas.each{|prop|
              estatus_anterior = prop.status
              prop.update(activa: false, status: estatus_anterior == 2 ? 20 : 7, status2: 7)
              id_devolver = prop.id_juega.to_i > 0 ? prop.id_juega.to_i : prop.id_banquea.to_i
              monto = prop.monto.to_f
              moneda = prop.moneda
              opc = actualizar_saldos(id_devolver, "Jugada devuelta Money Line (#{nombre})", monto, moneda, prop.id,2)
              if estatus_anterior == 2
                prop.update(operaciones_cajero_id: opc.id)
              end
           }
        end
    end
  end


  def devolver_apuestas_run_line(deporte_id,liga_id,match_id,nombre)
    ActiveRecord::Base.transaction do
        propuestas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 2, status: 1, activa: true)
        if propuestas.present?
           propuestas.each{|prop|
              estatus_anterior = prop.status
              prop.update(activa: false, status: estatus_anterior == 2 ? 20 : 7, status2: 7)
              id_devolver = prop.id_juega.to_i > 0 ? prop.id_juega.to_i : prop.id_banquea.to_i
              monto = prop.monto.to_f
              moneda = prop.moneda
              opc = actualizar_saldos(id_devolver, "Jugada devuelta Run Line/Spread (#{nombre})", monto, moneda, prop.id,2)
              if estatus_anterior == 2
                prop.update(operaciones_cajero_id: opc.id)
              end
           }
        end
    end
  end

  def devolver_apuestas_altabaja(deporte_id,liga_id,match_id,nombre)
    ActiveRecord::Base.transaction do
        propuestas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 3, status: 1, activa: true)
        if propuestas.present?
           propuestas.each{|prop|
              estatus_anterior = prop.status
              prop.update(activa: false, status: estatus_anterior == 2 ? 20 : 7, status2: 7)
              id_devolver = prop.id_juega.to_i > 0 ? prop.id_juega.to_i : prop.id_banquea.to_i
              monto = prop.monto.to_f
              moneda = prop.moneda
              tipo_mensa = prop.tipo_altabaja == 1 ? "Alta" : "Baja"
              opc = actualizar_saldos(id_devolver, "Jugada devuelta #{tipo_mensa} (#{nombre})", monto, moneda, prop.id,2)
              if estatus_anterior == 2
                prop.update(operaciones_cajero_id: opc.id)
              end
           }
        end
    end
  end


  def devolver_apuestas_una(id,detalle,nombre)
    tipo1 = ""
    tipo2 = ""
    ActiveRecord::Base.transaction do
        propuestas = PropuestasDeporte.find_by(id: id)
        if propuestas.present?
             estatus_anterior = propuestas.status
             propuestas.update(activa: false, status: estatus_anterior == 2 ? 20 : 7, status2: 7)
             opc1 = actualizar_saldos(propuestas.id_juega, "Jugada devuelta #{detalle} (#{nombre})", propuestas.monto, 2, propuestas.id,2)
             opc2 = actualizar_saldos(propuestas.id_banquea, "Jugada devuelta #{detalle} (#{nombre})", propuestas.cuanto_gana_completo, 2, propuestas.id,2)
             if estatus_anterior == 2
                propuestas.update(operaciones_cajero_id: [opc1.id,opc2.id])
             end
        end
    end
  end





  def devolver_apuestas_todas(deporte_id,liga_id,match_id,nombre, detalle,tipo_apuesta, status, fecha)
    ActiveRecord::Base.transaction do
        propuestas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: tipo_apuesta, status: status)
        if propuestas.present?
           propuestas.each{|prop|
             tipo_jugada = {1 => "Money Line", 2 => "Run Line", 3 => ""}
              if prop.tipo_apuesta == 3
                tipo_jugada[3] = prop.tipo_altabaja.to_i == 1 ? "Alta" : "baja"
              end
              estatus_anterior = prop.status
              if prop.status == 2
                prop.update(activa: false, status: 20, status2: 7)
              else
                prop.update(activa: false, status: 7, status2: 7)
              end
              monto = prop.monto.to_f.round(2)
              moneda = prop.moneda
              if estatus_anterior == 2
                if prop.accion_id == 1
                  opc1 = actualizar_saldos(prop.id_juega.to_i, "#{detalle} #{tipo_jugada[prop.tipo_apuesta]} (#{nombre})", monto, moneda, prop.id,2)
                  opc2 = actualizar_saldos(prop.id_banquea.to_i, "#{detalle} #{tipo_jugada[prop.tipo_apuesta]} (#{nombre})", prop.cuanto_gana_completo.to_f.round(2), moneda, prop.id,2)
                else
                  opc1 = actualizar_saldos(prop.id_banquea.to_i, "#{detalle} #{tipo_jugada[prop.tipo_apuesta]} (#{nombre})", monto, moneda, prop.id,2)
                  opc2 = actualizar_saldos(prop.id_juega.to_i, "#{detalle} #{tipo_jugada[prop.tipo_apuesta]} (#{nombre})", prop.cuanto_gana_completo.to_f.round(2), moneda, prop.id,2)
                end
                prop.update(operaciones_cajero_id: [opc1.id,opc2.id])
              else
                id_devolver = prop.id_juega.to_i > 0 ? prop.id_juega.to_i : prop.id_banquea.to_i
                actualizar_saldos(id_devolver, "#{detalle} #{tipo_jugada[prop.tipo_apuesta]} (#{nombre})", monto, moneda, prop.id,2)
              end
           }
        end
    end
  end



  def premiar_money_line(deporte_id,liga_id,match_id,nombre,equipo_gana,es_empate, fecha,equipo_res,equipo_ganador_nombre,equipo_pierde_nombre)

    ActiveRecord::Base.transaction do
        cruzadas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 1, status: 2, activa: false)
        if cruzadas.present?
          cruzadas.each{|prop|
            id_que_gana = 0
            cuanto_gana = 0
            equipo_nombre_ganador = ""
            valor_equipo = equipo_res[prop.equipo_id]
            if valor_equipo['res1'].to_f == valor_equipo['res2'].to_f and deporte_id =! 12
                devolver_apuestas_una(prop.id,"Empate",nombre)
            else
              if prop.equipo_id.to_i == equipo_gana.to_i
                 equipo_nombre_ganador = "Jugando " + equipo_ganador_nombre
                  if prop.accion_id == 1
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
              else
                  equipo_nombre_ganador = "Banqueando " + equipo_pierde_nombre
                  if prop.accion_id == 1
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
              end
            end
            opc = actualizar_saldos(id_que_gana, "Gano Money Line #{equipo_nombre_ganador} (#{prop.logro})", cuanto_gana, prop.moneda, prop.id,2)
            prop.update(activa: false, status: 20, status2: 8, id_gana: id_que_gana, operaciones_cajero_id: opc.id)

          }
        end
    end
  end


  def premiar_run_line(deporte_id,liga_id,match_id,nombre,equipo_gana,es_empate, fecha,equipo_res,equipo_ganador_nombre,equipo_pierde_nombre)

    ActiveRecord::Base.transaction do
        cruzadas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 2, status: 2, activa: false)
        if cruzadas.present?
          cruzadas.each{|prop|
            id_que_gana = 0
            cuanto_gana = 0
            equipo_nombre_ganador = ""
            valor_equipo = equipo_res[prop.equipo_id]

            if valor_equipo['res1'].to_f == valor_equipo['res2'].to_f
              devolver_apuestas_una(prop.id,"Run Line",nombre)
            else
                resultado_propuesta = valor_equipo['res1'].to_f + prop.carreras_dadas.to_f
                if resultado_propuesta > valor_equipo['res2'].to_f
                    equipo_nombre_ganador = "Jugando " + equipo_ganador_nombre
                    if prop.accion_id == 1
                      id_que_gana = prop.id_juega
                      cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                    else
                      id_que_gana = prop.id_juega
                      cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                    end
                else
                    equipo_nombre_ganador = "Banqueando " + equipo_pierde_nombre
                    if prop.accion_id == 1
                      id_que_gana = prop.id_banquea
                      cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                    else
                      id_que_gana = prop.id_banquea
                      cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                    end
                end
                opc = actualizar_saldos(id_que_gana, "Gano Run Line #{equipo_nombre_ganador} (#{prop.logro})", cuanto_gana, prop.moneda, prop.id,2)
                prop.update(activa: false, status: 20, status2: 8, id_gana: id_que_gana, operaciones_cajero_id: opc.id)
            end
          }
        end
    end
  end


  def premiar_altabaja(deporte_id,liga_id,match_id,nombre,equipo_gana,es_empate, fecha,suma_resultados)

    ActiveRecord::Base.transaction do
        cruzadas = PropuestasDeporte.where(deporte_id: deporte_id, liga_id: liga_id, match_id: match_id,created_at: fecha, tipo_apuesta: 3, status: 2, activa: false)
        if cruzadas.present?
          cruzadas.each{|prop|
          if es_empate
            devolver_apuestas_una(prop.id,"Alta Baja",nombre)
          else
            id_que_gana = 0
            cuanto_gana = 0
            if prop.alta_baja.to_f < suma_resultados.to_f
               if prop.tipo_altabaja.to_f == 1
                  tipo_mensa = "Jugando Alta"
                  if prop.accion_id == 1
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
               else
                 tipo_mensa = "Banqueando Baja"
                  if prop.accion_id == 1
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
               end
            else
               if prop.tipo_altabaja.to_f == 2
                  tipo_mensa = "Jugando Baja"
                  if prop.accion_id == 1
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_juega
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
               else
                tipo_mensa = "Banqueando Alta"
                  if prop.accion_id == 1
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.monto.to_f + prop.cuanto_gana.to_f).round(2)
                  else
                    id_que_gana = prop.id_banquea
                    cuanto_gana = (prop.cuanto_gana_completo.to_f + prop.cuanto_pierde).round(2)
                  end
               end
            end

                opc = actualizar_saldos(id_que_gana, "Gano #{tipo_mensa} (#{nombre})", cuanto_gana, prop.moneda, prop.id,2)
                prop.update(activa: false, status: 20, status2: 8, id_gana: id_que_gana, operaciones_cajero_id: opc.id)
          end
          }
        end
    end
  end



  def repremiar(deporte_id,match_id, fecha)
        matchs = Match.where(juego_id: deporte_id, id: match_id).last
        CuadreGeneralDeporte.where(juego_id: deporte_id, match_id: match_id, created_at: fecha ).delete_all
        prembus_rep = PremiosIngresadosDeporte.where(juego_id: deporte_id, match_id: match_id, created_at: fecha)
        if prembus_rep.present?
          prembus_rep.update_all(repremio: true, updated_at: DateTime.now)
        end
        buscar_propuestas = PropuestasDeporte.where(status: 20, deporte_id: deporte_id, match_id: match_id, created_at: fecha)
        if buscar_propuestas.present?
          buscar_propuestas.each{|prop|
            opcaj = OperacionesCajero.where(id: JSON.parse(prop.operaciones_cajero_id))
            desc = "Reverso error de premiacion: #{matchs.nombre}"
            opcaj.each{|ocaj_ind|
              monto = ocaj_ind.monto
              utsal = UsuariosTaquilla.find(ocaj_ind.usuarios_taquilla_id)
              if utsal.saldo_usd.to_f >= monto
                opcaj = OperacionesCajero.create(usuarios_taquilla_id: ocaj_ind.usuarios_taquilla_id, descripcion: desc, monto: (monto * -1), status: 0, moneda: 2,tipo: 4)
              else
                DevolucionSinSaldoDeporte.create(usuarios_taquilla_id: ocaj_ind.usuarios_taquilla_id, juego_id: deporte_id, monto: monto, nombre_match: matchs.nombre)
              end
            }
            prop.update(status: 2, status2: 2)
          }
        end

  end




  def premiar_juego
        @ids_ganadores = []
        iq1_id = params[:iq1_id].to_i
        iq2_id = params[:iq2_id].to_i
        iq3_id = 0
        es_empate = false
        eq1_resul = params[:eq1_resul].to_i
        eq2_resul = params[:eq2_resul].to_i
        fecha = params[:fecha].to_time.all_day
        equipo_ganador = eq1_resul > eq2_resul ? iq1_id : iq2_id
        resultado_mayor = eq1_resul > eq2_resul ? eq1_resul : eq2_resul
        buscar_match = Match.find_by(id: params[:id_match])
        buscar_match.update(activo: false)
        # ActionCable.server.broadcast "publicas_deporte_channel",data: {"tipo" => 2, "match_id" => [buscar_match.id]}
        match_bus = JSON.parse(buscar_match.data)
        finalizado = params[:finalizado].to_i
        deporte_id = params[:deporte_id].to_i
        liga_id = params[:liga_id].to_i
        match_id = params[:match_id].to_i
        nombre = buscar_match.nombre
        #runline
        equipo_res = Hash.new
        equipo_res[iq1_id] = {"res1" => eq1_resul, "res2" => eq2_resul}
        equipo_res[iq2_id] = {"res1" => eq2_resul, "res2" => eq1_resul}
        nombre_eq1 = ""
        nombre_eq2 = ""
        nombre_eq3 = ""
        id_api_eq1 = 0
        id_api_eq2 = 0
        id_api_eq3 = 0
        equipo_ganador_nombre = ""
        equipo_pierde_nombre = ""

        #runline
        suma_resultados = eq1_resul + eq2_resul
        if buscar_match.juego_id == 12
          if eq1_resul == eq2_resul
             equipo_ganador = match_bus['money_line']['c'][0]['i']
             nombre_eq3 = "Empate"
             equipo_ganador_nombre = "Empate"
             es_empate = true
          end
          nombre_eq1 = match_bus['money_line']['c'][1]['t']
          nombre_eq2 = match_bus['money_line']['c'][2]['t']
          id_api_eq1 = match_bus['money_line']['c'][1]['i']
          id_api_eq2 = match_bus['money_line']['c'][2]['i']
          id_api_eq3 = match_bus['money_line']['c'][0]['i']
        else
          nombre_eq1 = match_bus['money_line']['c'][0]['t']
          nombre_eq2 = match_bus['money_line']['c'][1]['t']
          id_api_eq1 = match_bus['money_line']['c'][0]['i']
          id_api_eq2 = match_bus['money_line']['c'][1]['i']
        end
        equipo_ganador_nombre = eq1_resul > eq2_resul ? nombre_eq1 : nombre_eq2
        equipo_pierde_nombre = eq1_resul > eq2_resul ? nombre_eq2 : nombre_eq1

        esrepremio = false
        if PremiosIngresadosDeporte.where(juego_id: deporte_id, match_id: match_id).count > 0
          repremiar(deporte_id,match_id, fecha)
          esrepremio = true
        end

        iq1_id = params[:iq1_id].to_i
        iq2_id = params[:iq2_id].to_i
        iq3_id = 0
        es_empate = false
        eq1_resul = params[:eq1_resul].to_i
        eq2_resul = params[:eq2_resul].to_i
        datos_equipos = {"eq1" => {"id" => iq1_id, "nombre" => nombre_eq1, "resultado" => eq1_resul}, "eq2" => {"id" => iq2_id,"nombre" => nombre_eq2, "resultado" => eq2_resul}}
        resultado = {"nombre" => buscar_match.nombre, "resultado"=> datos_equipos, "empate" => es_empate, "finalizado" => finalizado}

        @preming = PremiosIngresadosDeporte.create(usuario_premia: session[:usuario_actual]['id'], juego_id: deporte_id, liga_id: liga_id, match_id: match_id, resultado: resultado.to_json, repremio: false, created_at: params[:fecha].to_time)


        case finalizado
        when 1
          devolver_apuestas_todas(deporte_id,liga_id,match_id,nombre, 'Devolucion', [1,2,3], 1, fecha)
          premiar_money_line(buscar_match.juego_id,buscar_match.liga_id,buscar_match.id,buscar_match.nombre,equipo_ganador,es_empate, fecha,equipo_res,equipo_ganador_nombre,equipo_pierde_nombre)
          if buscar_match.juego_id != 12
             premiar_run_line(buscar_match.juego_id,buscar_match.liga_id,buscar_match.id,buscar_match.nombre,equipo_ganador,es_empate, fecha,equipo_res,equipo_ganador_nombre,equipo_pierde_nombre)
          end
          premiar_altabaja(buscar_match.juego_id,buscar_match.liga_id,buscar_match.id,buscar_match.nombre,equipo_ganador,es_empate, fecha,suma_resultados)
        when 2
          devolver_apuestas_todas(deporte_id,liga_id,match_id,nombre, 'Devolucion/Incompleto', [2,3],[1,2], fecha)
          premiar_money_line(buscar_match.juego_id,buscar_match.liga_id,buscar_match.id,buscar_match.nombre,equipo_ganador,es_empate, fecha,equipo_res,equipo_ganador_nombre,equipo_pierde_nombre)
        when 3
          devolver_apuestas_todas(deporte_id,liga_id,match_id,nombre, 'Dev/Suspendido', [1,2,3], [1,2], fecha)
        end

#############aqui puse la premiacion de caballos###########
    def buscar_datos_taquilla(taq_id, match_id, fecha)
        monto_divide1 = 0
        monto_divide2 = 0
        taq_divide = 0
        pro1 = PropuestasDeporte.where("id_juega = #{taq_id} or id_banquea = #{taq_id}").where(status2: 8, match_id: match_id, created_at: fecha, moneda: 2)
        # pre1 = PremiacionDeporte.where(id_gana: taq_id, repremiado: false, match_id: match_id, created_at: fecha, moneda: 2)
        totalprem1 = 0
        totalprem2 = 0
        monto_gana = 0
        monto_venta = 0
        pro1.each{|pre_temp1|
          monto_premio = 0
          monto_venta +=  pre_temp1.accion_id == 1 ? pre_temp1.monto.to_f : pre_temp1.cuanto_gana_completo.to_f
          if pre_temp1.id_gana == taq_id
              if pre_temp1.id_propone == taq_id
                 monto_premio = pre_temp1.cuanto_gana_completo.to_f
              else
                 monto_premio = pre_temp1.monto.to_f
              end
            # monto_premio = pre_temp1.accion_id == 1 ? pre_temp1.cuanto_gana_completo.to_f : pre_temp1.monto.to_f
            if UsuariosTaquilla.where(id: [pre_temp1.id_juega,pre_temp1.id_banquea]).pluck(:cobrador_id).group_by{|i| i}.count > 1
              if pre_temp1.id_juega.to_i == pre_temp1.id_gana.to_i
                taq_divide = pre_temp1.id_banquea
              else
                taq_divide = pre_temp1.id_juega
              end
              monto_divide1 += (monto_gana / 2)
            end
          end
          totalprem1 += monto_premio
        }
        return [monto_venta , 0, totalprem1.to_f, 0,taq_divide,monto_divide1,0]

    end


      #  ActionCable.server.broadcast "web_notifications_banca_channel_deporte",data: {"tipo" => 1}

       @estruc_1 = Hash.new
       # @estruc_2 = Hash.new
       objeto_inter = Hash.new
       intermediarios = Intermediario.all
       intermediarios.each{|inter|
         objeto_inter["#{inter.id.to_s}"] = {"id" => inter.id, "porcentaje_banca" => inter.porcentaje_banca}
         @estruc_1["I#{inter.id.to_s}"] = {"id" => inter.id, "venta"=> 0, "premio" => 0, "comision" => 0, "moneda" => 1}
         # @estruc_2["I#{inter.id.to_s}"] = {"id" => inter.id, "venta"=> 0, "premio" => 0, "comision" => 0, "moneda" => 2}
       }
       objeto_grupo = Hash.new
       grupos = Grupo.all
       if grupos.present?
          grupos.each{|grp|
            objeto_grupo["#{grp.id.to_s}"] = {"id" => grp.id, "inter_id" => grp.intermediario_id, "porcentaje_banca" => grp.porcentaje_banca, "porcentaje_intermediario" => grp.porcentaje_intermediario}
            @estruc_1["G#{grp.id.to_s}"] = {"id" => grp.id, "venta"=> 0, "premio" => 0, "comision" => 0, "moneda" => 1 }
            # @estruc_2["G#{grp.id.to_s}"] = {"id" => grp.id, "venta"=> 0, "premio" => 0, "comision" => 0, "moneda" => 2 }
          }
       end
       taquillas = UsuariosTaquilla.all
       taquillas.each{|taq|
         @estruc_1["T#{taq.id.to_s}"] = {
           "id" => taq.id,
           "venta"=> 0,
           "premio" => 0,
           "comision" => 0,
           "moneda" => 2 }
      }
      taquillas.each{|taq|
        datos = buscar_datos_taquilla(taq.id,match_id, fecha)
        monto_divide1 = datos[5].to_f
        # monto_divide2 = datos[6].to_f
        comision_taq1 = (((datos[2].to_f - monto_divide1) * taq.comision.to_f) / 100)
        # comision_taq2 = (((datos[3].to_f - monto_divide2) * taq.comision.to_f) / 100)
        comision_taq1g = ((datos[2].to_f * taq.comision.to_f) / 100)
        # comision_taq2g = ((datos[3].to_f * taq.comision.to_f) / 100)
        taq_divide = datos[4].to_i
        @estruc_1["T#{taq.id.to_s}"]["venta"] += datos[0]
        @estruc_1["T#{taq.id.to_s}"]["premio"] += datos[2]
        @estruc_1["T#{taq.id.to_s}"]["comision"] += comision_taq1
        # @estruc_2["T#{taq.id.to_s}"]["venta"] +=  datos[1]
        # @estruc_2["T#{taq.id.to_s}"]["premio"] += datos[3]
        # @estruc_2["T#{taq.id.to_s}"]["comision"] += comision_taq2
        if taq_divide > 0
          usertaq_div = @estruc_1["T#{taq_divide.to_s}"]["comis_taq"].to_f
          @estruc_1["T#{taq_divide.to_s}"]["comision"] += (monto_divide1 * usertaq_div) / 100
          # @estruc_2["T#{taq_divide.to_s}"]["comision"] += (monto_divide2 * usertaq_div) / 100
        end


        if objeto_grupo["#{taq.grupo_id.to_s}"]["inter_id"].to_i > 0
          @estruc_1["G#{taq.grupo_id.to_s}"]["venta"] += datos[0]
          @estruc_1["G#{taq.grupo_id.to_s}"]["premio"] += datos[2]
          comision_grupo1 = ((comision_taq1g.to_f * objeto_grupo["#{taq.grupo_id.to_s}"]["porcentaje_intermediario"].to_f) / 100)
          # comision_grupo2 = ((comision_taq2g.to_f * objeto_grupo["#{taq.grupo_id.to_s}"]["porcentaje_intermediario"].to_f) / 100)
          @estruc_1["G#{taq.grupo_id.to_s}"]["comision"] += comision_grupo1
          # @estruc_2["G#{taq.grupo_id.to_s}"]["venta"] +=  datos[1]
          # @estruc_2["G#{taq.grupo_id.to_s}"]["premio"] += datos[3]
          # @estruc_2["G#{taq.grupo_id.to_s}"]["comision"] += comision_grupo2
          onid = objeto_grupo["#{taq.grupo_id.to_s}"]["inter_id"].to_i
          @estruc_1["I#{onid.to_s}"]["venta"] += datos[0]
          @estruc_1["I#{onid.to_s}"]["premio"] += datos[2]
          @estruc_1["I#{onid.to_s}"]["comision"] += ((comision_taq1g.to_f * objeto_inter["#{onid.to_s}"]["porcentaje_banca"].to_f) / 100)
          # @estruc_2["I#{onid.to_s}"]["venta"] +=  datos[1]
          # @estruc_2["I#{onid.to_s}"]["premio"] += datos[3]
          # @estruc_2["I#{onid.to_s}"]["comision"] += ((comision_taq2g.to_f * objeto_inter["#{onid.to_s}"]["porcentaje_banca"].to_f) / 100)
        else
          @estruc_1["G#{taq.grupo_id.to_s}"]["venta"] += datos[0]
          @estruc_1["G#{taq.grupo_id.to_s}"]["premio"] += datos[2]
          @estruc_1["G#{taq.grupo_id.to_s}"]["comision"] += ((comision_taq1g.to_f * objeto_grupo["#{taq.grupo_id.to_s}"]["porcentaje_banca"].to_f) / 100)
          # @estruc_2["G#{taq.grupo_id.to_s}"]["venta"] +=  datos[1]
          # @estruc_2["G#{taq.grupo_id.to_s}"]["premio"] += datos[3]
          # @estruc_2["G#{taq.grupo_id.to_s}"]["comision"] += ((comision_taq2g.to_f * objeto_grupo["#{taq.grupo_id.to_s}"]["porcentaje_banca"].to_f) / 100)
        end
      }

     estructuras =  Estructura.where.not(tipo: 5)
     estructuras.each{|est|
       venta = 0
       premio = 0
       comision = 0
       venta2 = 0
       premio2 = 0
       comision2 = 0
       tipo_est = ""
       case est.tipo.to_i
       when 2
         tipo_est = "I"
       when 3
         tipo_est = "G"
       when 4
         tipo_est = "T"
       end
       if est.tipo.to_i == 4
         venta = @estruc_1["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f
         # venta2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f
       else
         if @estruc_1["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f > 0
           venta = @estruc_1["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f / 2
           # venta2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f / 2
         else
           venta = 0
           venta2 = 0
         end
       end


       premio = @estruc_1["#{tipo_est}#{est.tipo_id.to_s}"]["premio"].to_f
       comision = @estruc_1["#{tipo_est}#{est.tipo_id.to_s}"]["comision"].to_f
       # premio2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["premio"].to_f
       # comision2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision"].to_f
       CuadreGeneralDeporte.create(estructura_id: est.id, venta: venta , premio: premio, comision: comision, utilidad: 0, moneda: 2, match_id: match_id, juego_id: deporte_id)
       # CuadreGeneralCaballo.create(estructura_id: est.id, venta: venta2 , premio: premio2, comision: comision2, utilidad: 0, moneda: 2, carrera_id: id_carrera, hipodromo_id: hipodromo_id_bus)
     }
    ActionCable.server.broadcast "web_notifications_banca_channel_deporte", { data: {"tipo" => 2} }
    render json: {"status" => "OK", "msg" => "Carrera premiada con exito."}
      deportes = []
      if JornadaDeporte.where(fecha: Time.now.all_day).present?
        for juego in Juego.where(juego_id: Match.select(:juego_id).where(activo: true ).where("local >= ?", Time.now).pluck(:juego_id)).order(:nombre)
          ligas = []
          for liga in Liga.where(juego_id: juego.juego_id, activo: true,liga_id: Match.select(:liga_id).where(activo: true,juego_id: juego.juego_id).where("local >= ?", Time.now).pluck(:liga_id)).order(:nombre)
            matchs = []
                  for match in Match.select(:id,:nombre).where(activo: true,liga_id: liga.liga_id).where("local >= ?", Time.now).order(:local)
                    if match.nombre.length > 0
                      matchs << {"id" => match.id, "nombre" => match.nombre}
                    end
                  end
                  if matchs.length > 0
                    ligas << {"id" => liga.liga_id, "nombre" => liga.nombre, "matchs" => matchs}
                  end
          end
          if ligas.length > 0
            deportes << {"id" => juego.juego_id, "nombre" => juego.nombre, "ligas" => ligas}
          end
        end
      end
    ActionCable.server.broadcast "publicas_deporte_channel", { data: {"tipo" => "CLOSE_MATCH", "match_id" => [match_id], "data_menu" => deportes }}
    ActionCable.server.broadcast "publicas_deporte_channel", { data: {"tipo" => "UPDATE_SALDOS", "ids" => @ids_ganadores.uniq } }



  end

  private

  def actualizar_saldos(usuario_id, descripcion, monto, moneda, enj_id,tipo = 3)
      opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: moneda, tipo: tipo ,tipo_app: 2)
      @ids_ganadores << usuario_id
      return opcaj
      # CarrerasPremiada.create(premios_ingresado_id: @preming.id, operaciones_cajero_id: opcaj.id, carrera_id: @preming.carrera_id, usuarios_taquilla_id: usuario_id,  enjuego_id: enj_id, activo: true, status: 1)
  end


end
