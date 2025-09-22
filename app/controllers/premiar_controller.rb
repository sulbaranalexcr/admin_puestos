class PremiarController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :check_user_auth, only: [:show, :index]
  before_action :seguridad_cuentas, only: [:index]
  include ApplicationHelper

  def index
    @hipodromos = Hipodromo.all.order(:nombre_largo)
  end

  def show
    prem = PremioasIngresadosApi.find(params[:id].to_i)
    @hipodromos = Hipodromo.where(id: prem.hipodromo_id)
    @hipodromo_id = prem.hipodromo_id
    busca = Jornada.find(Carrera.find(prem.carrera_id).jornada_id)
    @carrera_id = busca.id
    @numero_carrera = Carrera.find(prem.carrera_id).numero_carrera
    render action: "index_prem"
  end

  def buscar_jornadas
    jornadas = Jornada.where(hipodromo_id: params[:id].to_i, fecha: (Time.now - 1.day).beginning_of_day..Time.now.end_of_day).order(:fecha)
    if jornadas.present?
      render json: { "jornadas" => jornadas }, methods: [:fecha_bonita]
    else
      render json: { "status" => "FAILD" }, status: 400
    end
  end

  def buscar_caballos
    caballos = CaballosCarrera.where(carrera_id: params[:id])
    if caballos.present?
      carrera = Carrera.find(params[:id])
      cantidad_total = CaballosCarrera.where(carrera_id: params[:id], retirado: false).count
      if carrera.activo
        # or carrera.hora_carrera > Time.now.strftime('%H:%M')
        render json: { "status" => "FAILD", "cantidad" => caballos.count, "hora" => carrera.hora_carrera[0, 5], "cantidad_total" => cantidad_total }
      else
        render json: { "status" => "OK", "cantidad" => caballos.count, "hora" => carrera.hora_carrera[0, 5], "cantidad_total" => cantidad_total }
      end
    else
      render json: { "status" => "FAILD" }
    end
  end

  def crear_caballos
    carrera_id = params[:id].to_i
    cantidad = params[:cantidad].to_i
    carrera = Carrera.find(params[:id])
    abreviatura = carrera.jornada.hipodromo.abreviatura
    #premiados = buscar_data_api("resultados/#{abreviatura}/#{carrera.numero_carrera}")
    premiados = PremioasIngresadosApi.where(carrera_id: params[:id].to_i).last
    if premiados.present?
      data_api = JSON.parse(premiados.resultado)
      @tiene_resultados = true
    else
      @tiene_resultados = false
    end
    caballos = CaballosCarrera.where(carrera_id: params[:id]).order("to_number(numero_puesto,'99')")
    premios = PremiosIngresado.where(carrera_id: params[:id].to_i).last
    if premios.present?
      @array = JSON.parse(premios.caballos)
    else
      @array = []
    end

    solo_normal = 0
    @caballos_array = []
    cantidad_total = 0
    @esupdate = false
    if caballos.present?
      @esupdate = true
      caballos.each { |ca|
        bus = @array.select { |item| item["puesto"] == ca.numero_puesto }
        valor = 0
        if bus.present?
          valor = bus[0]["llegada"].to_i
        end
        unless ca.retirado
          solo_normal += 1
        end
        sugerido = 0
        if premiados.present?
          busca_api_valor = data_api.select { |item| item["puesto"] == ca.numero_puesto.to_s }
          if busca_api_valor.present?
            sugerido = busca_api_valor[0]["llegada"]
          end
        end
        @caballos_array << { "id" => ca.id, "numero_puesto" => ca.numero_puesto, "nombre" => ca.nombre, "retirado" => ca.retirado, "llegada" => valor, "sugerido" => sugerido }
        cantidad_total = ca.numero_puesto
      }
    end
    canti_p = Carrera.find(carrera_id).jornada.hipodromo.cantidad_puestos

    if solo_normal < canti_p
      @canti_p = (solo_normal)
    else
      @canti_p = canti_p
    end

    # logger.info("***************************************************")
    # logger.info(@caballos_array.to_json)
    # logger.info("***************************************************")

    render partial: "premiar/caballos", layout: false
  end

  def repremiar(carrera_buscar,caballos)
    CuadreGeneralCaballo.where(carrera_id: carrera_buscar).delete_all

    premiacion = Premiacion.where(carrera_id: carrera_buscar.id, repremiado: false)
    premiacion.update_all(repremiado: true, updated_at: DateTime.now)
    carrebus = CarrerasPremiada.where(carrera_id: carrera_buscar.id, activo: true)
    prembus_rep = PremiosIngresado.where(carrera_id: carrera_buscar.id).order(:id)
    if prembus_rep.present?
      prembus_rep.update_all(repremio: true, updated_at: DateTime.now)
    end
    if carrebus.present?
      carrebus.each { |carb|
        opcaj = OperacionesCajero.find(carb.operaciones_cajero_id)
        monto = opcaj.monto
        moneda = opcaj.moneda
        desc = "Reverso error de premiacion Hipodromo: #{carrera_buscar.jornada.hipodromo.nombre}/C#  #{carrera_buscar.numero_carrera}"
        utsal = UsuariosTaquilla.find(carb.usuarios_taquilla_id)

        if utsal.usa_cajero_externo
          if prembus_rep.last.caballos == caballos.to_json
            opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc, monto: (monto * -1), status: 0, moneda: moneda, tipo: 4)
          else
            DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id, monto: monto, moneda: moneda)
          end
        else
          if utsal.saldo_usd.to_f >= monto
            opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc, monto: (monto * -1), status: 0, moneda: moneda, tipo: 4)
          else
            DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id, monto: monto, moneda: moneda)
          end
        end
        # end
        carb.update(activo: false)
        Enjuego.find(carb.enjuego_id).update(activo: true, status2: 1)
      }
      Propuesta.where(carrera_id: carrera_buscar).where("status2 > 7").update_all("status2 = status")
    end
  end

  def premiar
    id_carrera = params[:id].to_i
    caballos = params[:caballos]
    fecha = Carrera.find(id_carrera).jornada.fecha.strftime("%Y-%m-%d")
    @premios_array_cajero = []
    @retirar_array_cajero = []
    @cierrec_array_cajero = []
    @nojuega_array_cajero = []
    #    @ids_cajero_externo = UsuariosTaquilla.where(usa_cajero_externo: true).ids
    prop1 = Propuesta.where(carrera_id: id_carrera).pluck(:usuarios_taquilla_id).uniq
    enju1 = Enjuego.where(carrera_id: id_carrera).pluck(:usuarios_taquilla_id).uniq
    ids_dia = (prop1 + enju1).uniq
    @ids_cajero_externop = UsuariosTaquilla.where(id: ids_dia, usa_cajero_externo: true).as_json(only: [:id, :cliente_id])
    fecha_hora = (fecha + " " + Time.now.strftime("%H:%M")).to_time
    arreglo = []
    empates = Hash.new
    detalle = Hash.new
    carrera_buscar = Carrera.find(id_carrera)
    hipodromo_id_buscar =  carrera_buscar.jornada.hipodromo.id
    if params[:premia_api].present?
      @id_quien_premia = 1
    else
      @id_quien_premia = session[:usuario_actual]["id"]
    end

    begin
      ActiveRecord::Base.transaction do
        if PremiosIngresado.where(carrera_id: id_carrera).count > 0
          repremiar(carrera_buscar, caballos)
        end

        if carrera_buscar.activo
          #hora_carrera.gsub(":","").to_i >= Time.now.strftime("%H%M").to_i
          carrera_buscar.update(activo: false)
        end

        prupuestas = Propuesta.where(carrera_id: id_carrera, activa: true)
        if prupuestas.present?
          updates = prupuestas.update_all(activa: false, status: 4, status2: 7)
          prupuestas.each { |prop|
            descripcion = "Reverso/Premio #{prop.nombre_hipodromo}/C# #{prop.nombre_carrera}/Caballo: #{prop.nombre_caballo}/#{prop.tipo_apuesta}"
            OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id, descripcion: descripcion, monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
            busca_user = buscar_cliente_cajero(prop.usuarios_taquilla_id)
            if busca_user != "0"
              set_envios_api(4, busca_user, prop.tickets_detalle_id, prop.id, prop.monto.to_f, "Devolucio por cierre no cruzada")
            end
          }
        end

        retirados = []
        perdedores = []
        detalle[20] = []
        caballos.each { |puesto|
          if puesto["retirado"]
            retirados << puesto
          else
            if puesto["llegada"].to_i == 0
              perdedores << puesto
            else
              if empates.key?(puesto["llegada"].to_i)
                empates[puesto["llegada"].to_i] += 1
              else
                empates[puesto["llegada"].to_i] = 1
                detalle[puesto["llegada"].to_i] = []
              end
            end
            if puesto["llegada"].to_i == 0
              detalle[20] << puesto["id"].to_i
            else
              detalle[puesto["llegada"].to_i] << puesto["id"].to_i
            end
          end
        }

        arreglo_ordenado = detalle.sort_by { |_key, value| _key }.to_h

        cantidad_caballos_premiar = 0

        if ((detalle.count - 1) + perdedores.count) > 5
          cantidad_caballos_premiar = 5
        else
          cantidad_caballos_premiar = ((detalle.count + perdedores.count) - 2)
        end

        # logger.info("***************************************************")
        # logger.info(cantidad_caballos_premiar)
        # logger.info("***************************************************")
        # sleep 10

        puesto_formula = Hash.new
        puesto_formula[1] = {
          "todos" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "ganan_completo" => [1],
          "pierden" => [],
          "pierde_mitad" => 0,
          "nini" => 0,
          "gana_mitad" => 0,
        }
        puesto_formula[2] = {
          "todos" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "ganan_completo" => [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
          "pierden" => [1, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "pierde_mitad" => 2,
          "nini" => 3,
          "gana_mitad" => 4,
        }
        puesto_formula[3] = {
          "todos" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "ganan_completo" => [9, 10, 11, 12, 13, 14, 15, 16, 17],
          "pierden" => [1, 2, 3, 4, 5, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "pierde_mitad" => 6,
          "nini" => 7,
          "gana_mitad" => 8,
        }
        puesto_formula[4] = {
          "todos" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "ganan_completo" => [13, 14, 15, 16, 17],
          "pierden" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "pierde_mitad" => 10,
          "nini" => 11,
          "gana_mitad" => 12,
        }
        puesto_formula[5] = {
          "todos" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "ganan_completo" => [17],
          "pierden" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          "pierde_mitad" => 14,
          "nini" => 15,
          "gana_mitad" => 16,
        }

        jornada_bus = Jornada.find(carrera_buscar.jornada_id)

        hipodromo_bus = Hipodromo.find(jornada_bus.hipodromo_id)

        esrepremio = false
        @preming = PremiosIngresado.create(usuario_premia: @id_quien_premia, hipodromo_id: hipodromo_bus.id, jornada_id: jornada_bus.id, carrera_id: id_carrera, caballos: caballos.to_json, repremio: esrepremio, created_at: fecha_hora)
        prem_api_bus = PremioasIngresadosApi.where(carrera_id: id_carrera).last
        if prem_api_bus.present?
           prem_api_bus.update(status: 2)
        end

        retirar_tipo = []
        case cantidad_caballos_premiar
        # when 5
        #   retirar_tipo = [15,16,17]
        when 4
          retirar_tipo = [15, 16, 17]
        when 3
          retirar_tipo = [11, 12, 13, 14, 15, 16, 17]
        when 2
          retirar_tipo = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
        when 1
          retirar_tipo = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
        end

        if cantidad_caballos_premiar <= 5
          devolver_apuesta(retirar_tipo, "Devuelta/Retiro", fecha, fecha_hora, esrepremio, id_carrera)
        end
        # logger.info("***************************************************")
        # logger.info(retirar_tipo)
        # logger.info("***************************************************")

        retirados.each { |ret|
          bus_cab_prem = CaballosCarrera.find(ret["id"])
          bus_cab_prem.update(retirado: true)
          bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo_bus.id, carrera_id: id_carrera, caballos_carrera_id: bus_cab_prem.id)
          if bus_cab_ret_api.present?
            bus_cab_ret_api.update(status: 2, user_id: session[:usuario_actual]["id"])
          end
          ActionCable.server.broadcast "web_notifications_banca_channel", { data: { "tipo" => 2502, "cab_id" => bus_cab_prem.id }}
          devolver_jugada(ret["id"], "Reverso/Retirado", fecha, fecha_hora, esrepremio)
        }

        if ((detalle.count - 1) + perdedores.count) <= 5
          caballos_tomar = []
          caballos_tomarf = []
          if ((detalle.count - 1) + perdedores.count) == 5
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomar << arreglo_ordenado[3]
            caballos_tomar << arreglo_ordenado[4]
            caballos_tomarf = caballos_tomar.join(",").split(",")
            gana_lamitad(5, 14, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end

          if ((detalle.count - 1) + perdedores.count) == 4
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomar << arreglo_ordenado[3]
            caballos_tomarf = caballos_tomar.join(",").split(",")
            gana_lamitad(4, 10, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end

          if ((detalle.count - 1) + perdedores.count) == 3
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomarf = caballos_tomar.join(",").split(",")
            gana_lamitad(3, 6, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end

          if ((detalle.count - 1) + perdedores.count) == 2
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomarf = caballos_tomar.join(",").split(",")
            gana_lamitad(2, 2, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end
        end

        arreglo_ordenado.each { |index, value|
          if index.to_i != 20
            if value.length > 1
              prem(index, value, true, false, puesto_formula[index], fecha, fecha_hora)
            else
              prem(index, value, false, false, puesto_formula[index], fecha, fecha_hora)
            end
          end
        }

        perdedores.each { |per|
          pagar_perdedor(per["id"], fecha, fecha_hora, esrepremio)
        }
        if @cierrec_array_cajero.length > 0
           PremiacionApiJob.perform_async @cierrec_array_cajero, hipodromo_id_buscar, id_carrera, 4
        end
        if @retirar_array_cajero.length > 0
           PremiacionApiJob.perform_async @retirar_array_cajero, hipodromo_id_buscar, id_carrera, 3
        end
        if @nojuega_array_cajero.length > 0
           PremiacionApiJob.perform_async @nojuega_array_cajero, hipodromo_id_buscar, id_carrera, 5
        end
        if @premios_array_cajero.length > 0
           PremiacionApiJob.perform_async @premios_array_cajero, hipodromo_id_buscar, id_carrera, 1
        end

        #
        #     Llenar tabla cuadre_general
        def buscar_datos_taquilla(taq_id, carrera_id, taq_comision, grupo_id, cobrador_id)
          monto_divide2 = 0
          venta1 = Propuesta.where(usuarios_taquilla_id: taq_id, status: 2, carrera_id: carrera_id, moneda: 2).where(status2: [8,9,11,12]).sum(:monto)
          venta2 = Enjuego.where(usuarios_taquilla_id: taq_id, status: [1, 2], carrera_id: carrera_id, moneda: 2).where(status2: [8,9,11,12]).sum(:monto)
          total_premio = 0
          total_comision = 0
          quien_recibe = 0
          gano_grupo = 0
          comision_grupo = 0
          pre2 = Premiacion.where(id_gana: taq_id, repremiado: false, carrera_id: carrera_id, moneda: 2)
          pre2.each { |pre_temp2|
            if UsuariosTaquilla.where(id: [pre_temp2.id_quien_juega, pre_temp2.id_quien_banquea]).pluck(:cobrador_id).group_by { |i| i }.count > 1
              if pre_temp2.id_quien_juega.to_i == pre_temp2.id_gana.to_i
                quien_recibe = pre_temp2.id_quien_banquea
              else
                quien_recibe = pre_temp2.id_quien_juega
              end
              monto_divide2 += (pre_temp2.monto_pagado_completo.to_f / 2)
              comis_temp = ((pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100) / 2
              if taq_id.to_i == pre_temp2.id_gana.to_i
                @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
                @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
                @estruc_2["T#{taq_id.to_s}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
                @estruc_2["T#{quien_recibe}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
              else
                @estruc_2["T#{taq_id.to_s}"]["monto_otro_grupo"] += ((pre_temp2.monto_pagado_completo.to_f - comis_temp) * -1)
                @estruc_2["T#{quien_recibe}"]["monto_otro_grupo"] += (pre_temp2.monto_pagado_completo.to_f - comis_temp)
                @estruc_2["T#{taq_id.to_s}"]["perdio_oc"] += pre_temp2.monto_pagado_completo.to_f
                @estruc_2["T#{quien_recibe}"]["gano_oc"] += pre_temp2.monto_pagado_completo.to_f
              end
              @estruc_2["T#{taq_id.to_s}"]["comision_oc"] +=  comis_temp
              @estruc_2["T#{quien_recibe}"]["comision_oc"] += comis_temp
            else
              total_premio += pre_temp2.monto_pagado_completo.to_f
              total_comision += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
            end
            gano_grupo += pre_temp2.monto_pagado_completo.to_f
            comision_grupo += (pre_temp2.monto_pagado_completo.to_f * taq_comision.to_f) / 100
          }
            @estruc_2["T#{taq_id.to_s}"]["venta"] += venta1 + venta2
            @estruc_2["T#{taq_id.to_s}"]["premio"] += total_premio
            @estruc_2["T#{taq_id.to_s}"]["comision"] += total_comision

            @estruc_2["G#{grupo_id.to_s}"]["venta"] += venta1.to_f + venta2.to_f
            @estruc_2["G#{grupo_id.to_s}"]["premio"] += gano_grupo
            @estruc_2["G#{grupo_id.to_s}"]["comision"] += comision_grupo
            if @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i > 0
              onid = @objeto_grupo["#{grupo_id.to_s}"]["inter_id"].to_i
              @estruc_2["I#{onid.to_s}"]["venta"] += venta1.to_f + venta2.to_f
              @estruc_2["I#{onid.to_s}"]["premio"] += gano_grupo
              @estruc_2["I#{onid.to_s}"]["comision"] += comision_grupo
            end
        end

#        ActionCable.server.broadcast "web_notifications_banca_channel", data: { "tipo" => 1 }
        hipodromo_id_bus = Carrera.find(id_carrera).jornada.hipodromo.id

        @estruc_1 = Hash.new
        @estruc_2 = Hash.new
        @objeto_inter = Hash.new
        intermediarios = Intermediario.all
        intermediarios.each { |inter|
          @objeto_inter["#{inter.id.to_s}"] = { "id" => inter.id, "porcentaje_banca" => inter.porcentaje_banca }
          @estruc_2["I#{inter.id.to_s}"] = { "id" => inter.id, "venta" => 0, "premio" => 0 ,"gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
        }
        @objeto_grupo = Hash.new
        grupos = Grupo.all
        if grupos.present?
          grupos.each { |grp|
            @objeto_grupo["#{grp.id.to_s}"] = { "id" => grp.id, "inter_id" => grp.intermediario_id, "porcentaje_banca" => grp.porcentaje_banca, "porcentaje_intermediario" => grp.porcentaje_intermediario }
            @estruc_2["G#{grp.id.to_s}"] = { "id" => grp.id, "venta" => 0, "premio" => 0 ,"gano_oc" => 0, "perdio_oc" => 0, "comision" => 0, "comision_oc" => 0, "moneda" => 2 }
          }
        end

        taquillas = UsuariosTaquilla.select(:id,:grupo_id,:comision,:cobrador_id).where(id: ids_dia)
        taquillas.each { |taq|
          @estruc_2["T#{taq.id.to_s}"] = {
            "id" => taq.id,
            "venta" => 0,
            "premio" => 0,
            "gano_oc" => 0,
            "perdio_oc" => 0,
            "comision" => 0,
            "comision_oc" => 0,
            "moneda" => 2,
            "comis_taq" => taq.comision.to_f,
            "monto_otro_grupo" => 0,
          }
        }
        taquillas.each { |taq|
          datos = buscar_datos_taquilla(taq.id, id_carrera, taq.comision.to_f, taq.grupo_id, taq.cobrador_id)
        }

        estructuras = Estructura.where.not(tipo: 5)
        estructuras.each { |est|
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
            # when 5
            #   tipo_est = "C"
          end
          if est.tipo.to_i == 4 and ids_dia.include?(est.tipo_id) or est.tipo.to_i != 4
            venta = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["venta"].to_f
            premio = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["premio"].to_f
            comision = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision"].to_f
            gano_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["gano_oc"].to_f
            perdio_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["perdio_oc"].to_f
            comision_oc = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["comision_oc"].to_f
            momto_cobranza2 = @estruc_2["#{tipo_est}#{est.tipo_id.to_s}"]["monto_otro_grupo"].to_f

            CuadreGeneralCaballo.create(estructura_id: est.id, venta: venta, premio: premio, gano_oc: gano_oc, perdio_oc: perdio_oc, comision: comision, comision_oc: comision_oc, utilidad: 0, moneda: 2, carrera_id: id_carrera, hipodromo_id: hipodromo_id_bus, monto_otro_grupo: momto_cobranza2, created_at: fecha_hora)
          end
        }
        #
        #
        ActionCable.server.broadcast "web_notifications_banca_channel", { data: { "tipo" => 2 }}
        unless params[:premia_api].present?
          render json: { "status" => "OK", "msg" => "Carrera premiada con exito." }
        end
      end
      require "net/http"
      begin
        uri = URI("http://127.0.0.1:3003/notificaciones/premiado")
        res = Net::HTTP.post_form(uri, "id_carrera" => id_carrera.to_i)
      rescue
      end
    rescue Exception => ex
      # render json: {"status" => "FAILD", "msg" => "Error al premiar."}, status: 400
      logger.info("Error al premiar")
      logger.info(ex.message)
      raise
    end


#  logger.info("************ ojo termine depremiar**** premio***********************************")
#  logger.info(@premios_array_cajero)
#  logger.info("***************retiro************************************")
#  logger.info(@retirar_array_cajero)
#  logger.info("*********************cierre******************************")
#  logger.info(@cierrec_array_cajero)
#  logger.info("***************************no juega************************")
#  logger.info(@nojuega_array_cajero)
#  logger.info("***************************************************")





  end

  def prem(lugar, caballo_id, es_empate, esrepremio, puesto_formula, fecha, fecha_hora)
    case lugar
    when 1
      if es_empate
        enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: caballo_id, status: 2).pluck(:id), activo: true)
        enjuego.each { |enj|
          monto_juega2 = 0
          monto_banquea2 = 0
          if [18, 19, 20, 21, 22, 23, 24, 25, 26].include? enj.propuesta.tipo_id
            if enj.propuesta.accion_id == 1
              id_quien_gana = enj.propuesta.usuarios_taquilla_id
              monto_juega2 = enj.propuesta.monto.to_f
              monto_banquea2 = enj.propuesta.monto_gana_completo.to_f
              #(enj.propuesta.monto.to_f * TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f)
            else
              id_quien_gana = enj.usuarios_taquilla_id
              monto_juega2 = enj.propuesta.monto.to_f
              monto_banquea2 = enj.monto.to_f
            end
            enj.propuesta.update(status2: 10)

            moneda = enj.propuesta.moneda
            enj.update(activo: false, status: 2, status2: 10)
            descripcion = "Empate #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/Caballo: #{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"

            busca_user = buscar_cliente_cajero(enj.propuesta.usuarios_taquilla_id)
            if busca_user != "0"
              set_envios_api(1, busca_user, enj.propuesta.tickets_detalle_id, enj.propuesta.id.to_i, enj.propuesta.monto.to_f, "Devolucion por Empate")
            end
            busca_user = buscar_cliente_cajero(enj.usuarios_taquilla_id)
            if busca_user != "0"
              set_envios_api(1, busca_user, enj.tickets_detalle_id, enj.id.to_i, enj.propuesta.monto_gana_completo.to_f, "Devolucion por Empate")
            end

            if enj.propuesta.accion_id == 1
              actualizar_saldos(enj.propuesta.usuarios_taquilla_id, descripcion, monto_juega2.to_f, moneda, enj.id, 2)
              actualizar_saldos(enj.usuarios_taquilla_id, descripcion, monto_banquea2.to_f, moneda, enj.id, 2)
            else
              actualizar_saldos(enj.usuarios_taquilla_id, descripcion, monto_juega2.to_f, moneda, enj.id, 2)
              actualizar_saldos(enj.propuesta.usuarios_taquilla_id, descripcion, monto_banquea2.to_f, moneda, enj.id, 2)
            end

            if enj.propuesta.accion_id == 1
              monto_banqueado = (enj.propuesta.monto.to_f * TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f)
            else
              monto_banqueado = enj.propuesta.monto.to_f
            end

            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: 0, monto_pagado_completo: 0, created_at: fecha_hora)
          else
            transaction_id = 0
            reference_id = 0
            if enj.propuesta.accion_id == 1
              enj.propuesta.update(status2: 8)
              enj.update(status2: 9)
              id_quien_gana = enj.propuesta.usuarios_taquilla_id
              transaction_id = enj.propuesta.tickets_detalle_id
              reference_id = enj.propuesta_id
            else
              enj.propuesta.update(status2: 9)
              enj.update(status2: 8)
              id_quien_gana = enj.usuarios_taquilla_id
              transaction_id = enj.tickets_detalle_id
              reference_id = enj.id
            end

            monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
            cuanto_gana = (enj.monto.to_f + ((enj.monto.to_f * monto_tipo) - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
            cuanto_gana2 = ((enj.monto.to_f * monto_tipo) - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
            moneda = enj.propuesta.moneda
            enj.update(activo: false, status: 2)
            descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)

            busca_user = buscar_cliente_cajero(id_quien_gana)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id, reference_id, cuanto_gana.to_f, "Gano")
            end

            if enj.propuesta.accion_id == 1
              monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
            else
              monto_banqueado = enj.propuesta.monto.to_f
            end
            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f * monto_tipo), created_at: fecha_hora, id_gana: id_quien_gana)
            # if enj.propuesta.tipo_id != 1 and enj.propuesta.tipo_id < 18
            #   if enj.propuesta.accion_id == 1
            #     id_quien_gana = enj.usuarios_taquilla_id
            #   else
            #     id_quien_gana = enj.propuesta.usuarios_taquilla_id
            #   end
            #   monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
            #   if enj.propuesta.accion_id == 1
            #     monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
            #     cuanto_gana = (enj.monto.to_f + (enj.monto.to_f - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
            #     cuanto_gana2 = (enj.monto.to_f - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
            #   else
            #     monto_banqueado = enj.propuesta.monto.to_f
            #     cuanto_gana = (enj.propuesta.monto.to_f + (enj.propuesta.monto.to_f - ((enj.propuesta.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
            #     cuanto_gana2 = (enj.propuesta.monto.to_f - ((enj.propuesta.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
            #   end
            #   moneda = enj.propuesta.moneda
            #   enj.update(activo: false, status: 2)
            #   descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/Carrera: #{enj.propuesta.nombre_carrera}/Caballo: #{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            #   actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)
            #   Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f * monto_tipo), created_at: fecha_hora, id_gana: id_quien_gana)
            #end
          end
        }
      else
        enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: caballo_id, status: 2).pluck(:id), activo: true)
        enjuego.each { |enj|
          transaction_id = 0
          reference_id = 0
          tipoenjuego = enj.propuesta.tipo_id.to_i
          monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
          if enj.propuesta.accion_id == 1
            enj.propuesta.update(status2: 8)
            enj.update(status2: 9)
            id_quien_gana = enj.propuesta.usuarios_taquilla_id
            transaction_id = enj.propuesta.tickets_detalle_id
            reference_id = enj.propuesta_id
          else
            enj.propuesta.update(status2: 9)
            enj.update(status2: 8)
            id_quien_gana = enj.usuarios_taquilla_id
            transaction_id = enj.tickets_detalle_id
            reference_id = enj.id
          end
          cuanto_gana = (enj.monto.to_f + ((enj.monto.to_f * monto_tipo) - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
          moneda = enj.propuesta.moneda
          enj.update(activo: false, status: 2)
          descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
          actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)
          busca_user = buscar_cliente_cajero(id_quien_gana)
          if busca_user != "0"
            set_envios_api(1, busca_user, transaction_id, reference_id, cuanto_gana.to_f, "Gano")
          end

          if enj.propuesta.accion_id == 1
            monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
          else
            monto_banqueado = enj.propuesta.monto.to_f
          end
          cuanto_gana2 = ((enj.monto.to_f * monto_tipo) - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
          Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f * monto_tipo), created_at: fecha_hora, id_gana: id_quien_gana)
        }
      end
    when 2, 3, 4, 5

      # Rails.logger.info "***********************"
      # Rails.logger.info lugar
      # Rails.logger.info "***********************"

      enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: caballo_id, status: 2, tipo_id: puesto_formula["todos"]).pluck(:id), activo: true)
      enjuego.each { |enj|
        tipoenjuego = enj.propuesta.tipo_id.to_i

        if puesto_formula["ganan_completo"].include?(tipoenjuego)
          if enj.propuesta.accion_id == 1
            enj.propuesta.update(status2: 8)
            enj.update(status2: 9)
            id_quien_gana = enj.propuesta.usuarios_taquilla_id
            transaction_id = enj.propuesta.tickets_detalle_id
            reference_id = enj.propuesta_id
          else
            enj.propuesta.update(status2: 9)
            enj.update(status2: 8)
            id_quien_gana = enj.usuarios_taquilla_id
            transaction_id = enj.tickets_detalle_id
            reference_id = enj.id
          end
          monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
          cuanto_gana = (enj.monto.to_f + (enj.monto.to_f - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
          cuanto_gana2 = (enj.monto.to_f - ((enj.monto.to_f * monto_tipo) * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
          moneda = enj.propuesta.moneda
          enj.update(activo: false, status: 2)
          descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
          actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)

          busca_user = buscar_cliente_cajero(id_quien_gana)
          if busca_user != "0"
            set_envios_api(1, busca_user, transaction_id, reference_id, cuanto_gana.to_f, "Gano")
          end
          if enj.propuesta.accion_id == 1
            monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
          else
            monto_banqueado = enj.propuesta.monto.to_f
          end
          Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f * monto_tipo), created_at: fecha_hora, id_gana: id_quien_gana)
        else
          if puesto_formula["pierde_mitad"].to_i == tipoenjuego
            if enj.propuesta.accion_id == 1
              enj.propuesta.update(status2: 12)
              enj.update(status2: 11)
              id_quien_juega = enj.propuesta.usuarios_taquilla_id
              id_quien_banquea = enj.usuarios_taquilla_id
              transaction_id1 = enj.propuesta.tickets_detalle_id
              reference_id1 = enj.propuesta_id
              transaction_id2 = enj.tickets_detalle_id
              reference_id2 = enj.id
            else
              enj.propuesta.update(status2: 11)
              enj.update(status2: 12)
              id_quien_juega = enj.usuarios_taquilla_id
              id_quien_banquea = enj.propuesta.usuarios_taquilla_id
              transaction_id1 = enj.tickets_detalle_id
              reference_id1 = enj.id
              transaction_id2 = enj.propuesta.tickets_detalle_id
              reference_id2 = enj.propuesta_id
            end
            monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
            cuanto_pierde = (enj.propuesta.monto.to_f / 2)
            cuanto_gana = enj.monto.to_f + ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_banquea).comision.to_f / 100)))
            cuanto_gana2 = ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_banquea).comision.to_f / 100)))
            moneda = enj.propuesta.moneda
            descripcion = "Perdio la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_juega, descripcion, cuanto_pierde, moneda, enj.id, 2)
            descripcion2 = "Gano la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_banquea, descripcion2, cuanto_gana, moneda, enj.id)

            busca_user = buscar_cliente_cajero(id_quien_juega)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id1, reference_id1, cuanto_pierde.to_f, "Perdio la mitad")
            end

            busca_user = buscar_cliente_cajero(id_quien_banquea)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id2, reference_id2, cuanto_gana.to_f, "Gano la mitad")
            end

            monto_banqueado = enj.propuesta.monto.to_f
            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f / 2), created_at: fecha_hora, id_gana: id_quien_banquea)
            enj.update(activo: false, status: 2)
          elsif puesto_formula["nini"].to_i == tipoenjuego
            if enj.propuesta.accion_id == 1
              id_quien_juega = enj.propuesta.usuarios_taquilla_id
              id_quien_banquea = enj.usuarios_taquilla_id
              transaction_id1 = enj.propuesta.tickets_detalle_id
              reference_id1 = enj.propuesta_id
              transaction_id2 = enj.tickets_detalle_id
              reference_id2 = enj.id
            else
              id_quien_juega = enj.usuarios_taquilla_id
              id_quien_banquea = enj.propuesta.usuarios_taquilla_id
              transaction_id1 = enj.tickets_detalle_id
              reference_id1 = enj.id
              transaction_id2 = enj.propuesta.tickets_detalle_id
              reference_id2 = enj.propuesta_id
            end
            enj.propuesta.update(status2: 10)
            enj.update(status2: 10)
            cuanto_pierde = enj.propuesta.monto.to_f
            cuanto_gana = enj.propuesta.monto.to_f
            cuanto_gana2 = 0
            moneda = enj.propuesta.moneda
            descripcion = "Empate #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_juega, descripcion, cuanto_pierde, moneda, enj.id, 2)
            descripcion2 = "Empate #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_banquea, descripcion2, cuanto_gana, moneda, enj.id, 2)

            busca_user = buscar_cliente_cajero(id_quien_juega)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id1, reference_id1, cuanto_pierde.to_f, "Devolucion por Empate")
            end

            busca_user = buscar_cliente_cajero(id_quien_banquea)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id2, reference_id2, cuanto_gana.to_f, "Devolucion por Empate")
            end

            monto_banqueado = enj.propuesta.monto.to_f
            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: 0, created_at: fecha_hora)
            enj.update(activo: false, status: 2)
          elsif puesto_formula["gana_mitad"].to_i == tipoenjuego
            if enj.propuesta.accion_id == 1
              enj.propuesta.update(status2: 11)
              enj.update(status2: 12)
              id_quien_juega = enj.propuesta.usuarios_taquilla_id
              id_quien_banquea = enj.usuarios_taquilla_id
              transaction_id1 = enj.propuesta.tickets_detalle_id
              reference_id1 = enj.propuesta_id
              transaction_id2 = enj.tickets_detalle_id
              reference_id2 = enj.id
            else
              enj.propuesta.update(status2: 12)
              enj.update(status2: 11)
              id_quien_juega = enj.usuarios_taquilla_id
              id_quien_banquea = enj.propuesta.usuarios_taquilla_id
              transaction_id1 = enj.tickets_detalle_id
              reference_id1 = enj.id
              transaction_id2 = enj.propuesta.tickets_detalle_id
              reference_id2 = enj.propuesta_id
            end
            monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
            cuanto_gana = enj.monto.to_f + ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_juega).comision.to_f / 100)))
            cuanto_pierde = (enj.propuesta.monto.to_f / 2)
            cuanto_gana2 = ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_juega).comision.to_f / 100)))
            moneda = enj.propuesta.moneda
            descripcion = "Gano la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_juega, descripcion, cuanto_gana, moneda, enj.id)
            descripcion2 = "Perdio la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_banquea, descripcion2, cuanto_pierde, moneda, enj.id, 2)

            busca_user = buscar_cliente_cajero(id_quien_juega)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id1, reference_id1, cuanto_gana.to_f, "Gano la mitad")
            end

            busca_user = buscar_cliente_cajero(id_quien_banquea)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id2, reference_id2, cuanto_pierde.to_f, "Perdio la mitad")
            end

            monto_banqueado = enj.propuesta.monto.to_f
            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f / 2), created_at: fecha_hora, id_gana: id_quien_juega)
            enj.update(activo: false, status: 2)
          elsif puesto_formula["pierden"].include?(tipoenjuego)
            if enj.propuesta.accion_id == 1
              id_quien_gana = enj.usuarios_taquilla_id
              enj.propuesta.update(status2: 9)
              enj.update(status2: 8)
              transaction_id = enj.tickets_detalle_id
              reference_id = enj.id
            else
              enj.propuesta.update(status2: 8)
              enj.update(status2: 9)
              id_quien_gana = enj.propuesta.usuarios_taquilla_id
              transaction_id = enj.propuesta.tickets_detalle_id
              reference_id = enj.propuesta_id
            end
            monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
            if enj.propuesta.accion_id == 1
              monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
              cuanto_gana = ((enj.monto.to_f * monto_tipo) + (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
              cuanto_gana2 = (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
            else
              monto_banqueado = enj.propuesta.monto.to_f
              cuanto_gana = (enj.propuesta.monto.to_f + (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
              cuanto_gana2 = (enj.monto.to_f - (enj.propuesta.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
            end
            moneda = enj.propuesta.moneda
            enj.update(activo: false, status: 2)
            descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
            actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)
            busca_user = buscar_cliente_cajero(id_quien_gana)
            if busca_user != "0"
              set_envios_api(1, busca_user, transaction_id, reference_id, cuanto_gana.to_f, "Gano")
            end

            Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: enj.monto.to_f, created_at: fecha_hora, id_gana: id_quien_gana)
          end
        end
      }
    end
  end

  def devolver_jugada(id_caballo, detalle, fecha, fecha_hora, esrepremio)
    enjuego = Enjuego.where(propuesta_id: Propuesta.where(caballo_id: id_caballo, status: 2).pluck(:id), activo: true)
    enjuego.each { |enj|
      tipoenjuego = enj.propuesta.tipo_id.to_i
      monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
      if enj.propuesta.accion_id == 1
        id_quien_juega = enj.propuesta.usuarios_taquilla_id
        id_quien_banquea = enj.usuarios_taquilla_id
      else
        id_quien_juega = enj.usuarios_taquilla_id
        id_quien_banquea = enj.propuesta.usuarios_taquilla_id
      end
      if enj.propuesta.accion_id == 1
        monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
        cuanto_juega = enj.monto.to_f
        cuanto_banquea = (enj.monto.to_f * monto_tipo)
      else
        monto_banqueado = enj.propuesta.monto.to_f
        cuanto_juega = enj.monto.to_f
        cuanto_banquea = enj.propuesta.monto.to_f
      end

      cuanto_gana2 = 0
      moneda = enj.propuesta.moneda
      descripcion = "#{detalle} #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_juega, descripcion, cuanto_juega, moneda, enj.id, 2)
      descripcion2 = "#{detalle} #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_banquea, descripcion2, cuanto_banquea, moneda, enj.id, 2)
      Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: 0, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: 0, created_at: fecha_hora)
      enj.update(activo: false, status: 2, status2: 13)
      enj.propuesta.update(status: 4, status2: 13)
      busca_user = buscar_cliente_cajero(enj.propuesta.usuarios_taquilla.id)
      if busca_user != "0"
        set_envios_api(3, busca_user, enj.propuesta.tickets_detalle_id, enj.propuesta_id, enj.propuesta.monto.to_f, "Retiro de ejemplar")
      end
      busca_user = buscar_cliente_cajero(enj.usuarios_taquilla_id)
      if busca_user != "0"
        set_envios_api(3, busca_user, enj.tickets_detalle_id, enj.id, enj.propuesta.monto_gana_completo.to_f, "Retiro de ejemplar")
      end
    }
  end

  def pagar_perdedor(id_caballo, fecha, fecha_hora, esrepremio)
    enjuego = Enjuego.where(propuesta_id: Propuesta.where(status: 2, caballo_id: id_caballo).pluck(:id), activo: true)
    enjuego.each { |enj|
      trasaction_id1 = 0
      reference_id1 = 0
      tipoenjuego = enj.propuesta.tipo_id.to_i
      if enj.propuesta.accion_id == 1
        enj.propuesta.update(status2: 9)
        enj.update(status2: 8)
        id_quien_gana = enj.usuarios_taquilla_id
        trasaction_id1 = enj.tickets_detalle_id
        reference_id1 = enj.id
      else
        enj.propuesta.update(status2: 8)
        enj.update(status2: 9)
        id_quien_gana = enj.propuesta.usuarios_taquilla_id
        trasaction_id1 = enj.propuesta.tickets_detalle_id
        reference_id1 = enj.propuesta_id
      end
      monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
      if enj.propuesta.accion_id == 1
        monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
        cuanto_gana = ((enj.monto.to_f * monto_tipo) + (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
        cuanto_gana2 = (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
      else
        monto_banqueado = enj.propuesta.monto.to_f
        cuanto_gana = (enj.propuesta.monto.to_f + (enj.monto.to_f - (enj.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100))))
        cuanto_gana2 = (enj.monto.to_f - (enj.propuesta.monto.to_f * (UsuariosTaquilla.find(id_quien_gana).comision.to_f / 100)))
      end
      moneda = enj.propuesta.moneda
      enj.update(activo: false, status: 2)
      descripcion = "Gano #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_gana, descripcion, cuanto_gana, moneda, enj.id)
      Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: 0, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: enj.monto.to_f, created_at: fecha_hora, id_gana: id_quien_gana)

      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != "0"
        set_envios_api(1, busca_user, trasaction_id1, reference_id1, cuanto_gana.to_f, "Gano")
      end
    }
  end

  def devolver_apuesta(id_tipo, detalle, fecha, fecha_hora, esrepremio, id_carrera)
    enjuego = Enjuego.where(propuesta_id: Propuesta.where(tipo_id: id_tipo, status: 2, carrera_id: id_carrera).pluck(:id), activo: true)
    enjuego.each { |enj|
      tipoenjuego = enj.propuesta.tipo_id.to_i
      enj.propuesta.update(status: 4, status2: 7)
      monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
      if enj.propuesta.accion_id == 1
        id_quien_juega = enj.propuesta.usuarios_taquilla_id
        id_quien_banquea = enj.usuarios_taquilla_id
      else
        id_quien_juega = enj.usuarios_taquilla_id
        id_quien_banquea = enj.propuesta.usuarios_taquilla_id
      end
      if enj.propuesta.accion_id == 1
        monto_banqueado = (enj.propuesta.monto.to_f * monto_tipo)
        cuanto_juega = enj.monto.to_f
        cuanto_banquea = (enj.monto.to_f * monto_tipo)
      else
        monto_banqueado = enj.propuesta.monto.to_f
        cuanto_juega = enj.monto.to_f
        cuanto_banquea = enj.propuesta.monto.to_f
      end

      cuanto_gana2 = 0
      moneda = enj.propuesta.moneda
      descripcion = "#{detalle} #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_juega, descripcion, cuanto_juega, moneda, enj.id, 2)
      descripcion2 = "#{detalle} #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_banquea, descripcion2, cuanto_banquea, moneda, enj.id, 2)
      Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: 0, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: 0, created_at: fecha_hora)
      enj.update(activo: false, status: 2, status2: 7)
      busca_user = buscar_cliente_cajero(enj.propuesta.usuarios_taquilla.id)
      if busca_user != "0"
        set_envios_api(5, busca_user, enj.propuesta.tickets_detalle_id,enj.propuesta_id, enj.propuesta.monto.to_f, "Devolucion")
      end
      busca_user = buscar_cliente_cajero(enj.usuarios_taquilla_id)
      if busca_user != "0"
        set_envios_api(5, busca_user, enj.tickets_detalle_id, enj.id, enj.propuesta.monto_gana_completo.to_f, "Devolucion")
      end
    }
  end

  def gana_lamitad(lugar, tipo_id, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
    enjuego = Enjuego.where(propuesta_id: Propuesta.where(tipo_id: tipo_id, status: 2, carrera_id: id_carrera, caballo_id: caballos_tomarf).pluck(:id), activo: true)
    enjuego.each { |enj|
      trasaction_id1 = 0
      reference_id1 = 0
      trasaction_id2 = 0
      reference_id2 = 0
      if enj.propuesta.accion_id == 1
        enj.propuesta.update(status2: 11)
        enj.update(status2: 12)
        id_quien_juega = enj.propuesta.usuarios_taquilla_id
        id_quien_banquea = enj.usuarios_taquilla_id
        trasaction_id1 = enj.propuesta.tickets_detalle_id
        reference_id1 = enj.propuesta_id
        trasaction_id2 = enj.tickets_detalle_id
        reference_id2 = enj.id
      else
        enj.propuesta.update(status2: 12)
        enj.update(status2: 11)
        id_quien_juega = enj.usuarios_taquilla_id
        id_quien_banquea = enj.propuesta.usuarios_taquilla_id
        trasaction_id1 = enj.tickets_detalle_id
        reference_id1 = enj.id
        trasaction_id2 = enj.propuesta.tickets_detalle_id
        reference_id2 = enj.propuesta_id
      end
      monto_tipo = TipoApuesta.find(enj.propuesta.tipo_id).forma_pagar.to_f
      cuanto_gana = enj.monto.to_f + ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_juega).comision.to_f / 100)))
      cuanto_pierde = (enj.propuesta.monto.to_f / 2)
      cuanto_gana2 = ((enj.monto.to_f / 2) - ((enj.monto.to_f / 2) * (UsuariosTaquilla.find(id_quien_juega).comision.to_f / 100)))
      moneda = enj.propuesta.moneda
      descripcion = "Gano la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_juega, descripcion, cuanto_gana, moneda, enj.id)
      descripcion2 = "Perdio la mitad #{enj.propuesta.nombre_hipodromo}/C# #{enj.propuesta.nombre_carrera}/#{enj.propuesta.nombre_caballo}/#{enj.propuesta.tipo_apuesta}"
      actualizar_saldos(id_quien_banquea, descripcion2, cuanto_pierde, moneda, enj.id, 2)
      monto_banqueado = enj.propuesta.monto.to_f
      Premiacion.create(moneda: moneda, carrera_id: enj.propuesta.carrera_id, caballos_carrera_id: enj.propuesta.caballo_id, tipo_apuesta: enj.propuesta.tipo_id, id_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.usuarios_taquilla_id : enj.usuarios_taquilla_id), id_quien_banquea: (enj.propuesta.accion_id == 1 ? enj.usuarios_taquilla_id : enj.propuesta.usuarios_taquilla_id), monto_quien_juega: (enj.propuesta.accion_id == 1 ? enj.propuesta.monto : enj.monto), monto_quien_banquea: monto_banqueado, usuario_premia_id: @id_quien_premia, llegada_caballo: lugar, repremiado: esrepremio, monto_pagado: cuanto_gana2, monto_pagado_completo: (enj.monto.to_f / 2), created_at: fecha_hora, id_gana: id_quien_juega)
      enj.update(activo: false, status: 2)
      busca_user = buscar_cliente_cajero(id_quien_juega)
      if busca_user != "0"
        set_envios_api(1, busca_user, trasaction_id1, reference_id1, cuanto_gana.to_f, "Gana la mitad")
      end

      busca_user = buscar_cliente_cajero(id_quien_banquea)
      if busca_user != "0"
        set_envios_api(1, busca_user, trasaction_id2, reference_id2, cuanto_pierde.to_f, "Pierde la mitad")
      end
    }
  end

  private

  def actualizar_saldos(usuario_id, descripcion, monto, moneda, enj_id, tipo = 3)
    # opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: moneda, tipo: tipo)
    opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: moneda, tipo: 3)
    CarrerasPremiada.create(premios_ingresado_id: @preming.id, operaciones_cajero_id: opcaj.id, carrera_id: @preming.carrera_id, usuarios_taquilla_id: usuario_id, enjuego_id: enj_id, activo: true, status: 1)
  end

  # enjuego = Enjuego.where(created_at: fecha.to_time.all_da

  #1- Premiar tipo
  #3- Retirar caballos
  #4- cerrar_carrera
  #5- No entra en juego

  def set_envios_api(tipo, user_id, transaction_id, reference_id, monto, details = "")
    case tipo.to_i
    when 1
      @premios_array_cajero << { "id" => user_id[0], "taq_id" => user_id[1],  "transaction_id" => transaction_id, "reference_id" => reference_id, "amount" => monto, "details" => details }
    when 3
      @retirar_array_cajero << { "id" => user_id[0], "taq_id" => user_id[1], "transaction_id" => transaction_id, "reference_id" => reference_id, "amount" => monto, "details" => details }
    when 4
      @cierrec_array_cajero << { "id" => user_id[0], "taq_id" => user_id[1], "transaction_id" => transaction_id, "reference_id" => reference_id, "amount" => monto, "details" => details }
    when 5
      @nojuega_array_cajero << { "id" => user_id[0], "taq_id" => user_id[1], "transaction_id" => transaction_id, "reference_id" => reference_id, "amount" => monto, "details" => details }
    end
  end

  def buscar_cliente_cajero(id)
    busqueda = @ids_cajero_externop.select { |a| a["id"] == id }
    if busqueda.present?
      return [busqueda[0]["cliente_id"],busqueda[0]["id"]]
    else
      return "0"
    end
  end
end
