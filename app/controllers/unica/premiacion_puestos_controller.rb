module Unica
  class PremiacionPuestosController < ApplicationController
    skip_before_action :verify_authenticity_token
    #    before_action :check_user_auth, only: [:show, :index]
    #    before_action :seguridad_cuentas, only: [:index]
    include ApplicationHelper
    include PremiarHelper

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
      render action: 'index_prem'
    end

    def buscar_proxima_hip
      carreras = Jornada.where(hipodromo_id: params[:id].to_i,
                               fecha: (Time.now - 1.day).beginning_of_day..Time.now.end_of_day).last
                        .carrera.where(activo: true).order(:id)
      if carreras.present?
        render json: { 'carreras' => carreras }
      else
        render json: { 'status' => 'FAILD' }, status: 400
      end
    end

    def buscar_jornadas
      jornadas = Jornada.where(hipodromo_id: params[:id].to_i,
                               fecha: (Time.now - 3.day).beginning_of_day..Time.now.end_of_day).order(:fecha)
      if jornadas.present?
        render json: { 'jornadas' => jornadas }, methods: [:fecha_bonita]
      else
        render json: { 'status' => 'FAILD' }, status: 400
      end
    end

    def buscar_caballos
      caballos = CaballosCarrera.where(carrera_id: params[:id])
      if caballos.present?
        carrera = Carrera.find(params[:id])
        cantidad_total = CaballosCarrera.where(carrera_id: params[:id], retirado: false).count
        if carrera.activo
          render json: { 'status' => 'FAILD', 'cantidad' => caballos.count, 'hora' => carrera.hora_carrera[0, 5],
                         'cantidad_total' => cantidad_total }
        else
          render json: { 'status' => 'OK', 'cantidad' => caballos.count, 'hora' => carrera.hora_carrera[0, 5],
                         'cantidad_total' => cantidad_total }
        end
      else
        render json: { 'status' => 'FAILD' }
      end
    end

    def crear_caballos
      carrera_id = params[:id].to_i
      cantidad = params[:cantidad].to_i
      carrera = Carrera.find(params[:id])
      hipodromo = carrera.jornada.hipodromo
      abreviatura = hipodromo.abreviatura
      # aqui lo de nyra
      results = []
      @premiados_nyra = []
      @retirados_nyra_complet = []
      @retirados_nyra = []

      id_nyra = Hipodromos::Carreras.races_by_hipodromo(hipodromo.codigo_nyra, carrera.numero_carrera.to_i)
      if id_nyra.present?
        results = Hipodromos::Carreras.results(params[:id], id_nyra)
        unless results[:status] == 'FAILD'
          @premiados_nyra = results['results'].sort
          @retirados_nyra_complet = results['scratches']
          @retirados_nyra = results['scratches'].join('-')
        end
      end
      # begin
      #   carrera_id_nyra = Hipodromos::Carreras.extrac_nyra_id_race(hipodromo, carrera.numero_carrera.to_i)
      #   results = Hipodromos::Carreras.results(params[:id], carrera_id_nyra)

      #   @premiados_nyra = results[0]
      #   @retirados_nyra_complet = results[1]
      #   @retirados_nyra = results[1].join('-')
      # rescue
      # end

      # fin de nyra

      premiados = PremioasIngresadosApi.where(carrera_id: params[:id].to_i).last
      if premiados.present?
        data_api = JSON.parse(premiados.resultado)
        @tiene_resultados = true
      else
        @tiene_resultados = false
      end
      caballos = CaballosCarrera.where(carrera_id: params[:id]).order(Arel.sql("to_number(numero_puesto,'99')"))
      premios = PremiosIngresado.where(carrera_id: params[:id].to_i).last
      @array = if premios.present?
                 JSON.parse(premios.caballos)
               else
                 []
               end

      solo_normal = 0
      @caballos_array = []
      cantidad_total = 0
      @esupdate = false
      if caballos.present?
        @esupdate = true
        caballos.each do |ca|
          bus = @array.select { |item| item['puesto'] == ca.numero_puesto }
          valor = 0
          valor = bus[0]['llegada'].to_i if bus.present?
          solo_normal += 1 unless ca.retirado
          sugerido = 0
          if premiados.present?
            busca_api_valor = data_api.select { |item| item['puesto'] == ca.numero_puesto.to_s }
            sugerido = busca_api_valor[0]['llegada'] if busca_api_valor.present?
          end
          busca_nyra_valor = @premiados_nyra.find { |item| item[1] == ca.numero_puesto.to_s }
          sugerido_nyra = busca_nyra_valor.present? ? busca_nyra_valor[0] : 0
          @caballos_array << { 'id' => ca.id, 'numero_puesto' => ca.numero_puesto, 'nombre' => ca.nombre,
                               'retirado' => ca.retirado, 'llegada' => valor, 'sugerido' => sugerido,
                               'sugerido_nyra' => sugerido_nyra }
          cantidad_total = ca.numero_puesto
        end
      end
      canti_p = Carrera.find(carrera_id).jornada.hipodromo.cantidad_puestos

      @canti_p = if solo_normal < canti_p
                   solo_normal
                 else
                   canti_p
                 end

      # logger.info("***************************************************")
      # logger.info(@caballos_array.to_json)
      # logger.info("***************************************************")
      @comparacion = @caballos_array.map { |a| a['sugerido_nyra'] } == @caballos_array.map { |b| b['sugerido'] }
      render partial: 'unica/premiacion_puestos/caballos', layout: false
    end

    def repremiar(carrera_buscar, caballos)
      CuadreGeneralCaballosPuesto.where(carrera_id: carrera_buscar).delete_all
      # CuadreGeneralCaballo.where(carrera_id: carrera_buscar).delete_all

      premiacion = PremiacionCaballosPuesto.where(carrera_id: carrera_buscar.id).delete_all
      # premiacion2 = Premiacion.where(carrera_id: carrera_buscar.id).delete_all

      # carrebus = CarrerasPPuesto.where(carrera_id: carrera_buscar.id, activo: true)
      # carrebus2 = CarrerasPLogro.where(carrera_id: carrera_buscar.id, activo: true)
      prembus_rep = PremiosIngresado.where(carrera_id: carrera_buscar.id).order(:id)
      prembus_rep.update_all(repremio: true, updated_at: DateTime.now) if prembus_rep.present?
      # if carrebus.present?
      #   carrebus.each do |carb|
      #     opcaj = OperacionesCajero.find(carb.operaciones_cajero_id)
      #     monto = opcaj.monto
      #     moneda = 2
      #     desc = "Reverso error de premiacion Hipodromo: #{carrera_buscar.jornada.hipodromo.nombre}/C#  #{carrera_buscar.numero_carrera}"
      #     utsal = UsuariosTaquilla.find(carb.usuarios_taquilla_id)

      #     if utsal.usa_cajero_externo
      #       if prembus_rep.last.caballos == caballos.to_json
      #         opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc,
      #                                          monto: (monto * -1), status: 0, moneda: 2, tipo: 4, tipo_app: 1)
      #       else
      #         DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id,
      #                                   monto: monto, moneda: 2)
      #       end
      #     elsif utsal.saldo_usd.to_f >= monto
      #       opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc,
      #                                        monto: (monto * -1), status: 0, moneda: 2, tipo: 4, tipo_app: 1)
      #     else
      #       DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id,
      #                                 monto: monto, moneda: 2)
      #     end
      #     # end
      #     carb.update(activo: false)
      #     #  Enjuego.find(carb.enjuego_id).update(activo: true, status2: 1)
      #   end
      # end
      PropuestasCaballosPuesto.where(carrera_id: carrera_buscar).where.not(status2: 13).where('status2 > 7').update_all('status2 = 2, status = 2, premiada = false, updated_at = now()')
      # if carrebus2.present?
      #   carrebus2.each do |carb|
      #     opcaj = OperacionesCajero.find(carb.operaciones_cajero_id)
      #     monto = opcaj.monto
      #     desc = "Reverso error de premiacion Hipodromo: #{carrera_buscar.jornada.hipodromo.nombre}/C#  #{carrera_buscar.numero_carrera}"
      #     utsal = UsuariosTaquilla.find(carb.usuarios_taquilla_id)
      #     if utsal.usa_cajero_externo
      #       if prembus_rep.last.caballos == caballos.to_json
      #         opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc,
      #                                          monto: (monto * -1), status: 0, moneda: 2, tipo: 4, tipo_app: 3)
      #       else
      #         DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id,
      #                                   monto: monto, moneda: 2)
      #       end
      #     elsif utsal.saldo_usd.to_f >= monto
      #       opcaj = OperacionesCajero.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, descripcion: desc,
      #                                        monto: (monto * -1), status: 0, moneda: 2, tipo: 4, tipo_app: 3)
      #     else
      #       DevolucionSinSaldo.create(usuarios_taquilla_id: carb.usuarios_taquilla_id, carrera_id: carrera_buscar.id,
      #                                 monto: monto, moneda: 2)
      #     end
      #     # end
      #     carb.update(activo: false)
      #     #  Enjuego.find(carb.enjuego_id).update(activo: true, status2: 1)
      #   end
      # end
      # PropuestasCaballo.where(carrera_id: carrera_buscar).where.not(status2: 13).where('status2 > 7').update_all('status2 = 2, status = 2, premiada = false, updated_at = now()')
    end

    # def send_data_premios(url, carrera_id, id_api, caballos)
    #   uri = URI.parse(url)
    #   https = Net::HTTP.new(uri.host, uri.port)
    #   https.use_ssl = true
    #   req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
    #   req.body = { 'id' => carrera_id, 'id_api' => id_api, 'caballos' => caballos, 'premia_api' => false, 'recibe_puestos' => true }.to_json
    #   https.request(req)
    # rescue StandardError => e
    #   puts e  
    # end
    def send_to_api(carrera_id, id_api, data_cab)
      uri = URI.parse('https://horses.betsolutiongroup.com/api/premiar_interno')
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, initheader = { 'Content-Type' => 'application/json' })
      req.body = { 'carrera_id' => carrera_id, 'id_api' => id_api, 'caballos' => data_cab }.to_json
      https.request(req)
    rescue StandardError => e
      puts e
    end

    def change_cab(caballos, carrera_id)
      caballos.map do |a| 
        { 'id' => CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: a['puesto']).id, 
          'puesto' => a['puesto'], 
          'retirado' => a['retirado'], 
          'llegada' => a['llegada'] 
        } 
        end
    end

    def premiar_manual
      carrera = Carrera.find(params[:id])
      send_to_api(carrera.id, carrera.id_api, params[:caballos])
    end
   
    def change_cab(caballos, carrera_id)
      caballos.map do |a|
        { 'id' => CaballosCarrera.find_by(carrera_id: carrera_id, numero_puesto: a['puesto']).id,
          'puesto' => a['puesto'],
          'retirado' => a['retirado'],
          'llegada' => a['llegada']
        }
        end
    end

    def premiar_puestos
      # id_carrera = params[:id].to_i
      # search_carrera = Carrera.find(id_carrera)
      search_carrera = if params[:recibe_puestos].present?
                         Carrera.find_by(id_api: params[:id_api])
                       else
                         Carrera.find(params[:id].to_i)
                       end
      carrera = search_carrera
      return unless carrera.present?                 
      id_carrera = search_carrera.id
      caballos = params[:id_api].present? ? change_cab(params[:caballos], id_carrera) : params[:caballos]
      # caballos = params[:caballos]
      new_caballos = []
      usuario_premia = params[:recibe_puestos].present? ? User.first.id : session[:usuario_actual]['id']
      # if params[:premia_api].present? or params[:recibe_puestos].present?
      #   caballos_origen = search_carrera.caballos_carrera
      #   caballos_origen.each do |cabx|
      #     find_horse = caballos.find { |a| a['id'].to_i == cabx.id }
      #     llegadax = find_horse.present? ? find_horse['llegada'] : '0'
      #     new_caballos << { "id"=> cabx.id, "puesto"=> cabx.numero_puesto, "llegada"=> llegadax, "retirado"=> cabx.retirado }
      #   end
      #   caballos = new_caballos
      # end
      caballos = params[:id_api].present? ? change_cab(params[:caballos], id_carrera) : params[:caballos]
      # sistemas = ["https://admin.unpuestos.com/unica/premiacion_puestos/premiar_puestos",
      #             "#{ENV['tablas_url']}/unica/premiacion_tablas/premiar_tablas",
      #             "https://admin.rojosynegros.com/unica/premiacion_rojonegro/premiar_rojonegro",
      #             "https://admin.piramidehipica.com/unica/premiacion_piramide/premiar_piramide"]

      # if ENV['reenvia_apis'] == 'SI'
      #   unless params[:premia_api].present?
      #     sistemas.each do |sis_url|
      #       Thread.new { 
      #         send_data_premios(sis_url, id_carrera, search_carrera.id_api, caballos)
      #       }
      #     end
      #   end
      # end

      return if caballos.select { |a| a['llegada'].to_i.positive? }.length.zero?

      fecha = search_carrera.jornada.fecha.strftime('%Y-%m-%d')
      @premios_array_cajero = []
      @retirar_array_cajero = []
      @cierrec_array_cajero = []
      @nojuega_array_cajero = []
      @usuarios_interno_ganan = []
      ids_dia = PropuestasCaballosPuesto.where(carrera_id: id_carrera).map do |a|
                  [a.id_juega] + [a.id_banquea]
                end.join(',').split(',').uniq.map! { |e| e.to_i }.reject { |k| k == 0 }
      ids_dia = if ids_dia.present?
                  ids_dia.uniq
                else
                  []
                end
      ids_dia2 = PropuestasCaballo.where(carrera_id: id_carrera).map do |a|
                   [a.id_juega] + [a.id_banquea]
                 end.join(',').split(',').uniq.map! { |e| e.to_i }.reject { |k| k == 0 }
      ids_dia2 = if ids_dia2.present?
                   ids_dia2.uniq
                 else
                   []
                 end

      ActiveRecord::Base.connection.execute("update carreras set updated_at = now(), activo = false where id = #{id_carrera}")
      ActionCable.server.broadcast 'publicas_deporte_channel', {
                                   data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS', 'id' => id_carrera.to_i }}
      @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
      @ids_cajero_externop =  ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json
      fecha_hora = (fecha + ' ' + Time.now.strftime('%H:%M')).to_time
      arreglo = []
      empates = {}
      detalle = {}
      carrera_buscar = Carrera.find(id_carrera)
      hipodromo_id_buscar = carrera_buscar.jornada.hipodromo.id
      @id_quien_premia = usuario_premia

      #    begin
      ActiveRecord::Base.transaction do
        repremiar(carrera_buscar, caballos) if PremiosIngresado.where(carrera_id: id_carrera).count > 0

        prupuestas = PropuestasCaballosPuesto.where(carrera_id: id_carrera, activa: true, status: 1)
        if prupuestas.present?
          prupuestas.each do |prop|
            if prop.id_propone == prop.id_juega
              tra_id = prop.tickets_detalle_id_juega
              ref_id = prop.reference_id_juega
            else
              tra_id = prop.tickets_detalle_id_banquea
              ref_id = prop.reference_id_banquea
            end
            descripcion = "Reverso/No igualado #{prop.texto_jugada}"
            # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
            #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 1)
            busca_user = buscar_cliente_cajero(prop.id_propone)
            if busca_user != '0'
              set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualado', 0)
            end
          end
          updates = prupuestas.update_all(activa: false, status: 4, status2: 7, premiada: true, updated_at: DateTime.now)
        end

        # prupuestas_logros = PropuestasCaballo.where(carrera_id: id_carrera, activa: true, status: 1)
        # if prupuestas_logros.present?
        #   prupuestas_logros.each do |prop|
        #     if prop.id_propone == prop.id_juega
        #       tra_id = prop.tickets_detalle_id_juega
        #       ref_id = prop.reference_id_juega
        #     else
        #       tra_id = prop.tickets_detalle_id_banquea
        #       ref_id = prop.reference_id_banquea
        #     end
        #     descripcion = "Reverso/No igualado #{prop.texto_jugada}"
        #     # OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone, descripcion: descripcion,
        #     #                          monto: monto_local(prop.id_propone, prop.monto), status: 0, moneda: 2, tipo: 2, tipo_app: 3)
        #     busca_user = buscar_cliente_cajero(prop.id_propone)
        #     if busca_user != '0'
        #       set_envios_api(4, busca_user, tra_id, ref_id, prop.monto, 'Devolucion por cierre no igualado', 0)
        #     end
        #   end
        #   updates = prupuestas_logros.update_all(activa: false, status: 4, status2: 7, premiada: true, updated_at: DateTime.now)
        # end

        retirados = []
        perdedores = []
        detalle[50] = []
        caballos.each do |puesto|
          if puesto['retirado']
            retirados << puesto
          else
            if puesto['llegada'].to_i == 0
              perdedores << puesto
            elsif empates.key?(puesto['llegada'].to_i)
              empates[puesto['llegada'].to_i] += 1
            else
              empates[puesto['llegada'].to_i] = 1
              detalle[puesto['llegada'].to_i] = []
            end
            if puesto['llegada'].to_i == 0
              detalle[50] << puesto['id'].to_i
            else
              detalle[puesto['llegada'].to_i] << puesto['id'].to_i
            end
          end
        end

        arreglo_ordenado = detalle.sort_by { |key, _value| key }.to_h

        # cantidad_caballos_premiar = 0
        
        caballos_que_corren = detalle.sum { |hor| hor[1].count }
        # # ((detalle.count - 1) + perdedores.count)
        # cantidad_caballos_premiar = if caballos_que_corren > 5
        #                               5
        #                             else
        #                               # ((detalle.count + perdedores.count) - 2)
        #                               detalle.select { |alh| alh != 50}.sum { |hor| hor[1].count }
        #                             end

        puesto_formula = {}
        todos_array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
        puesto_formula[1] = {
          'todos' => todos_array,
          'ganan_completo' => [1],
          'pierden' => [],
          'pierde_mitad' => [],
          'nini' => [],
          'gana_mitad' => []
        }
        puesto_formula[2] = {
          'todos' => todos_array,
          'ganan_completo' => [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
          'pierden' => [1, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          'pierde_mitad' => 2,
          'nini' => 3,
          'gana_mitad' => 4
        }
        puesto_formula[3] = {
          'todos' => todos_array,
          'ganan_completo' => [9, 10, 11, 12, 13, 14, 15, 16, 17],
          'pierden' => [1, 2, 3, 4, 5, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          'pierde_mitad' => 6,
          'nini' => 7,
          'gana_mitad' => 8
        }
        puesto_formula[4] = {
          'todos' => todos_array,
          'ganan_completo' => [13, 14, 15, 16, 17],
          'pierden' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          'pierde_mitad' => 10,
          'nini' => 11,
          'gana_mitad' => 12
        }
        puesto_formula[5] = {
          'todos' => todos_array,
          'ganan_completo' => [17],
          'pierden' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25, 26],
          'pierde_mitad' => 14,
          'nini' => 15,
          'gana_mitad' => 16
        }

        #  logger.info("***************************************************")
        #  logger.info(puesto_formula[5])
        #  logger.info("***************************************************")

        jornada_bus = Jornada.find(carrera_buscar.jornada_id)
        hipodromo_bus = Hipodromo.find(jornada_bus.hipodromo_id)

        esrepremio = false
        @preming = PremiosIngresado.create(usuario_premia: @id_quien_premia, hipodromo_id: hipodromo_bus.id,
                                           jornada_id: jornada_bus.id, carrera_id: id_carrera, caballos: caballos.to_json, repremio: esrepremio, created_at: fecha_hora)
        # prem_api_bus = PremioasIngresadosApi.where(carrera_id: id_carrera).last
        # prem_api_bus.update(status: 2) if prem_api_bus.present?

        retirar_tipo = []

        case caballos_que_corren
        when 5
          retirar_tipo = [15, 16, 17]
        when 4
          retirar_tipo = [11, 12, 13, 14, 15, 16, 17]
        when 3
          retirar_tipo = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
        when 2
          retirar_tipo = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
        end

        if caballos_que_corren <= 5
          devolver_apuesta(retirar_tipo, 'No entra en juego', fecha, fecha_hora, esrepremio, id_carrera)
          # devolver_apuesta_logros(retirar_tipo, 'No entra en juego', fecha, fecha_hora, esrepremio, id_carrera)
        end

        retirados.each do |ret|
          bus_cab_prem = CaballosCarrera.find(ret['id'])
          # actualizar_propuestas_no_enjuego(ret['id'])

          bus_cab_prem.update(retirado: true)
          # bus_cab_ret_api = CaballosRetiradosConfirmacion.find_by(hipodromo_id: hipodromo_bus.id,
          #                                                         carrera_id: id_carrera, caballos_carrera_id: bus_cab_prem.id)
          # bus_cab_ret_api.update(status: 2, user_id: @id_quien_premia) if bus_cab_ret_api.present?
          #            ActionCable.server.broadcast "web_notifications_banca_channel", data: { "tipo" => 2502, "cab_id" => bus_cab_prem.id }
          devolver_jugada(ret['id'], 'Reverso/Retirado', fecha, fecha_hora, esrepremio)
          # devolver_jugada_logros(ret['id'], 'Reverso/Retirado', fecha, fecha_hora, esrepremio)
        end

        if caballos_que_corren <= 5
          caballos_tomar = []
          caballos_tomarf = []
          if caballos_que_corren == 5
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomar << arreglo_ordenado[3]
            caballos_tomar << arreglo_ordenado[4]
            caballos_tomarf = caballos_tomar.join(',').split(',')
            gana_lamitad(5, 14, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end
          if caballos_que_corren == 4
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomar << arreglo_ordenado[3]
            caballos_tomarf = caballos_tomar.join(',').split(',')
            gana_lamitad(4, 10, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end

          if caballos_que_corren == 3
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomar << arreglo_ordenado[2]
            caballos_tomarf = caballos_tomar.join(',').split(',')
            gana_lamitad(3, 6, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end

          if caballos_que_corren == 2
            caballos_tomar << arreglo_ordenado[1]
            caballos_tomarf = caballos_tomar.join(',').split(',')
            gana_lamitad(2, 2, esrepremio, fecha, fecha_hora, id_carrera, caballos_tomarf)
          end
        end

        arreglo_ordenado.each do |index, value|
          if index.to_i != 50
            if value.length > 1
              prem(index, value, true, false, puesto_formula[index], fecha, fecha_hora)
              # prem_logros(index, value, true, false, puesto_formula[index], fecha, fecha_hora)
            else
              prem(index, value, false, false, puesto_formula[index], fecha, fecha_hora)
              # prem_logros(index, value, false, false, puesto_formula[index], fecha, fecha_hora)
            end
          end
        end

        perdedores.each do |per|
          pagar_perdedor(per['id'], fecha, fecha_hora, esrepremio)
          # pagar_perdedor_logros(id_carrera, fecha, fecha_hora, esrepremio)
        end

        if @cierrec_array_cajero.length.positive?
          PremiacionApiJob.perform_async @cierrec_array_cajero, hipodromo_id_buscar, id_carrera, 4
        end
        if @retirar_array_cajero.length.positive?
          PremiacionApiJob.perform_async @retirar_array_cajero, hipodromo_id_buscar, id_carrera, 3
        end
        if @nojuega_array_cajero.length.positive?
          PremiacionApiJob.perform_async @nojuega_array_cajero, hipodromo_id_buscar, id_carrera, 5
        end
        if @premios_array_cajero.length.positive?
          programar_en = Time.now 
          PremiacionApiJob.perform_at(programar_en, @premios_array_cajero, hipodromo_id_buscar, id_carrera, 1)
        end
        #
        #     Llenar tabla cuadre_general

        # if @cierrec_array_cajero.length.positive?
        #   ApiData::Server.send_data(@cierrec_array_cajero, hipodromo_id_buscar, id_carrera, 4)
        # end
        # if @retirar_array_cajero.length.positive?
        #   ApiData::Server.send_data(@retirar_array_cajero, hipodromo_id_buscar, id_carrera, 3)
        # end
        # if @nojuega_array_cajero.length.positive?
        #   ApiData::Server.send_data(@nojuega_array_cajero, hipodromo_id_buscar, id_carrera, 5)
        # end
        # ApiData::Server.send_data(@premios_array_cajero, hipodromo_id_buscar, id_carrera, 1)

        if @usuarios_interno_ganan.length > 0
          # saldos_enviar = UsuariosTaquilla.where(id: @usuarios_interno_ganan).pluck(:id, :saldo_usd)
          # ActionCable.server.broadcast 'publicas_deporte_channel', {
          #                              data: { 'tipo' => 'UPDATE_SALDOS_PREMIOS', 'data' => saldos_enviar }}
        end
        # generar_reportes_puestos(1, id_carrera, ids_dia, fecha_hora)
        # generar_reportes_puestos(2, id_carrera, ids_dia2, fecha_hora)
      end
      #   rescue
      #   end
    end


    def actualizar_propuestas_no_enjuego(cab_id)
      retirar = PropuestasCaballosPuesto.where(caballos_carrera_id: cab_id).where.not(status: [1, 2])
      retirar.update_all(activa: false, status: 4, status2: 13, updated_at: DateTime.now)
    end


    def prem(lugar, caballo_id, es_empate, _esrepremio, puesto_formula, _fecha, fecha_hora)
      case lugar
      when 1
        if es_empate
          enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: caballo_id, status: 2, premiada: false)
          enjuego.each do |enj|
            monto_juega2 = 0
            monto_banquea2 = 0
            if [18, 19, 20, 21, 22, 23, 24, 25, 26].include? enj.tipo_apuesta_id
              id_quien_propone = enj.id_propone
              id_quien_toma = enj.id_propone == enj.id_juega ? enj.id_banquea : enj.id_juega
              monto_propone = enj.monto
              monto_gana = (id_quien_propone == enj.id_juega) ? enj.cuanto_gana :
              if enj.id_propone == enj.id_juega
                detalle_tipo_juego = 'Jugo'
                detalle_tipo_juego2 = 'Banqueo'
              else
                detalle_tipo_juego = 'Banqueo'
                detalle_tipo_juego2 = 'Jugo'
              end
              monto_toma = enj.cuanto_gana_completo
              reference_id_propone = enj.id_propone == enj.id_juega ? enj.reference_id_juega : enj.reference_id_banquea
              reference_id_toma = enj.id_propone == enj.id_juega ? enj.reference_id_banquea : enj.reference_id_juega
              tickets_detalle_id_propone = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
              tickets_detalle_id_toma = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
              descripcion = "Dev/Empate #{detalle_tipo_juego} #{enj.texto_jugada}"
              actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)
              descripcion2 = "Dev/Empate #{detalle_tipo_juego2} #{enj.texto_jugada}"
              actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
              enj.update(activa: false, status: 4, status2: 10, premiada: true)
              busca_user = buscar_cliente_cajero(enj.id_propone)
              if busca_user != '0'
                set_envios_api(1, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f,
                               'Devolucion/Empate', 0)
              end
              busca_user = buscar_cliente_cajero(id_quien_toma)
              if busca_user != '0'
                set_envios_api(1, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f,
                               'Devolucion/Empate', 0)
              end
            else
              gana_completo(enj, fecha_hora)
            end
          end
        else
          enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: caballo_id, status: 2, premiada: false)
          enjuego.each do |enj|
            gana_completo(enj, fecha_hora)
          end
        end
      when 2, 3, 4, 5
        enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: caballo_id, status: 2,
                                                 tipo_apuesta_id: puesto_formula['todos'], premiada: false)
        enjuego.each do |enj|
          tipoenjuego = enj.tipo_apuesta_id.to_i
          if puesto_formula['ganan_completo'].include?(tipoenjuego)
            gana_completo(enj, fecha_hora)
          elsif puesto_formula['pierde_mitad'].to_i == tipoenjuego
            pierde_lamitad(enj, fecha_hora)
          elsif puesto_formula['nini'].to_i == tipoenjuego
            devolver_nini(enj, 'Devolucion/nini')
          elsif puesto_formula['gana_mitad'].to_i == tipoenjuego
            gana_lamitad_ind(enj, fecha_hora)
          elsif puesto_formula['pierden'].include?(tipoenjuego)
            pierde_completo_ind(enj, fecha_hora)
          end
        end
      end
    end

    def prem_logros(lugar, caballo_id, _es_empate, _esrepremio, _puesto_formula, _fecha, fecha_hora)
      case lugar
      when 1
        enjuego = PropuestasCaballo.where(caballos_carrera_id: caballo_id, status: 2, premiada: false)
        enjuego.each do |enj|
          gana_completo_logros(enj, fecha_hora)
        end
      end
    end

    def pierde_completo_ind(enj, fecha_hora)
      id_quien_gana = enj.id_banquea
      id_quien_pierde = enj.id_juega
      porce_comis = UsuariosTaquilla.find(enj.id_banquea).comision.to_f
      if enj.id_juega == enj.id_propone
        monto_primario = enj.cuanto_gana_completo.to_f
        monto_secundario = enj.monto.to_f - ((enj.monto.to_f * porce_comis) / 100)
        monto_reporte = enj.monto.to_f
        cuanto_gana_completo = monto_primario + enj.monto.to_f
      else
        monto_primario = enj.monto.to_f
        monto_secundario = enj.cuanto_gana.to_f
        monto_reporte = enj.cuanto_gana_completo.to_f
        cuanto_gana_completo = monto_primario + enj.cuanto_gana_completo.to_f
      end
      cuanto_gana = monto_primario + monto_secundario

      descripcion = "Gano #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        comis = if enj.id_propone == enj.id_juega
                  enj.monto.to_f
                else
                  enj.cuanto_gana_completo.to_f
                end
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_gana.to_f,
                       descripcion, comis, agente)
      end
      enj.update(activa: false, status2: 8, id_gana: id_quien_gana, premiada: true, id_pierde: id_quien_pierde)
      PremiacionCaballosPuesto.create(moneda: 2, carrera_id: enj.carrera_id,
                                      id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                                      monto_pagado_completo: monto_reporte, created_at: fecha_hora)
    end

    def pierde_completo_ind_logros(enj, fecha_hora)
      id_quien_gana = enj.id_banquea
      id_quien_pierde = enj.id_juega
      porce_comis = UsuariosTaquilla.find(enj.id_banquea).comision.to_f
      if enj.id_juega == enj.id_propone
        monto_primario = enj.cuanto_gana_completo.to_f
        monto_secundario = enj.monto.to_f - ((enj.monto.to_f * porce_comis) / 100)
        cuanto_gana_completo = monto_primario + enj.monto.to_f
      else
        monto_primario = enj.monto.to_f
        monto_secundario = enj.cuanto_gana.to_f
        cuanto_gana_completo = monto_primario + enj.cuanto_gana_completo.to_f
      end
      cuanto_gana = monto_primario + monto_secundario

      descripcion = "Gano #{enj.texto_jugada}"
      actualizar_saldos(2, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        comis = enj.monto.to_f
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"

        set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_gana.to_f,
                       descripcion, comis, agente)
      end
      enj.update(activa: false, status2: 8, id_gana: id_quien_gana, premiada: true, id_pierde: id_quien_pierde)
      Premiacion.create(moneda: 2, carrera_id: enj.carrera_id, caballos_carrera_id: enj.caballos_carrera_id,
                        id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                        monto_pagado_completo: enj.monto.to_f, created_at: fecha_hora)
    end

    def pagar_perdedor(id_caballo, _fecha, fecha_hora, _esrepremio)
      enjuego = PropuestasCaballosPuesto.where(status: 2, caballos_carrera_id: id_caballo, premiada: false)
      enjuego.each do |enj|
        pierde_completo_ind(enj, fecha_hora)
      end
    end

    def pagar_perdedor_logros(carrera_id, _fecha, fecha_hora, _esrepremio)
      enjuego = PropuestasCaballo.where(status: 2, carrera_id: carrera_id, premiada: false)
      enjuego.each do |enj|
        pierde_completo_ind_logros(enj, fecha_hora)
      end
    end

    ### devolver nini
    def devolver_nini(enj, detalle)
      id_quien_propone = enj.id_propone
      id_quien_toma = enj.id_propone == enj.id_juega ? enj.id_banquea : enj.id_juega
      monto_propone = enj.monto
      if enj.id_propone == enj.id_juega
        detalle_tipo_juego = 'Jugo'
        detalle_tipo_juego2 = 'Banqueo'
      else
        detalle_tipo_juego = 'Banqueo'
        detalle_tipo_juego2 = 'Jugo'
      end
      monto_toma = enj.cuanto_gana_completo
      reference_id_propone = enj.id_propone == enj.id_juega ? enj.reference_id_juega : enj.reference_id_banquea
      reference_id_toma = enj.id_propone == enj.id_juega ? enj.reference_id_banquea : enj.reference_id_juega
      tickets_detalle_id_propone = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
      tickets_detalle_id_toma = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
      descripcion = "#{detalle} #{detalle_tipo_juego} #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)
      descripcion2 = "#{detalle} #{detalle_tipo_juego2} #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
      enj.update(activa: false, status: 4, status2: 10, premiada: true)
      busca_user = buscar_cliente_cajero(enj.id_propone)
      if busca_user != '0'
        set_envios_api(1, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f, detalle, 0, '')
      end
      busca_user = buscar_cliente_cajero(id_quien_toma)
      if busca_user != '0'
        set_envios_api(1, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f, detalle, 0, '')
      end
    end

    def devolver_apuesta(id_tipo, _detalle, _fecha, _fecha_hora, _esrepremio, id_carrera)
      enjuego = PropuestasCaballosPuesto.where(tipo_apuesta_id: id_tipo, status: 2, carrera_id: id_carrera,
                                               premiada: false)
      devolver_completo(enjuego, 7, 'No entra en juego', 5) if enjuego.present?
    end

    def devolver_jugada(id_caballo, _detalle, _fecha, _fecha_hora, _esrepremio)
      enjuego = PropuestasCaballosPuesto.where(caballos_carrera_id: id_caballo, status: 2, premiada: false)
      devolver_completo(enjuego, 13, 'Devolucion/Retiro', 3)
    end

    ### retiro y ni entra en juego
    def devolver_completo(enjuego, estado, detalle, tipo_envio)
      enjuego.each do |enj|
        id_quien_propone = enj.id_propone
        id_quien_toma = enj.id_propone == enj.id_juega ? enj.id_banquea : enj.id_juega
        monto_propone = enj.monto
        if enj.id_propone == enj.id_juega
          detalle_tipo_juego = 'Jugo'
          detalle_tipo_juego2 = 'Banqueo'
        else
          detalle_tipo_juego = 'Banqueo'
          detalle_tipo_juego2 = 'Jugo'
        end
        monto_toma = enj.cuanto_gana_completo
        reference_id_propone = enj.id_propone == enj.id_juega ? enj.reference_id_juega : enj.reference_id_banquea
        reference_id_toma = enj.id_propone == enj.id_juega ? enj.reference_id_banquea : enj.reference_id_juega
        tickets_detalle_id_propone = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_juega : enj.tickets_detalle_id_banquea
        tickets_detalle_id_toma = enj.id_propone == enj.id_juega ? enj.tickets_detalle_id_banquea : enj.tickets_detalle_id_juega
        descripcion = "#{detalle} #{detalle_tipo_juego} #{enj.texto_jugada}"
        actualizar_saldos(1, id_quien_propone, descripcion, monto_propone, 2, enj.id, 2)
        descripcion2 = "#{detalle} #{detalle_tipo_juego2} #{enj.texto_jugada}"
        actualizar_saldos(1, id_quien_toma, descripcion2, monto_toma, 2, enj.id, 2)
        enj.update(activa: false, status: 4, status2: estado, premiada: true)
        busca_user = buscar_cliente_cajero(enj.id_propone)
        if busca_user != '0'
          set_envios_api(tipo_envio, busca_user, tickets_detalle_id_propone, reference_id_propone, monto_propone.to_f,
                         detalle, 0, '')
        end
        busca_user = buscar_cliente_cajero(id_quien_toma)
        if busca_user != '0'
          set_envios_api(tipo_envio, busca_user, tickets_detalle_id_toma, reference_id_toma, monto_toma.to_f, detalle, 0, '')
        end
      end
    end

    def devolver_apuesta_logros(id_tipo, _detalle, _fecha, _fecha_hora, _esrepremio, id_carrera)
      enjuego = PropuestasCaballo.where(tipo_apuesta_id: id_tipo, status: 2, carrera_id: id_carrera, premiada: false)
      devolver_completo(enjuego, 7, 'No entra en juego', 5)
    end

    def devolver_jugada_logros(id_caballo, _detalle, _fecha, _fecha_hora, _esrepremio)
      enjuego = PropuestasCaballo.where(caballos_carrera_id: id_caballo, status: 2, premiada: false)
      devolver_completo(enjuego, 13, 'Devolucion/Retiro', 3)
    end

    def gana_lamitad(_lugar, tipo_id, _esrepremio, _fecha, fecha_hora, id_carrera, caballos_tomarf)
      enjuego = PropuestasCaballosPuesto.where(tipo_apuesta_id: tipo_id, status: 2, carrera_id: id_carrera,
                                               caballos_carrera_id: caballos_tomarf, premiada: false)
      enjuego.each do |enj|
        id_quien_gana = enj.id_juega
        id_quien_pierde = enj.id_banquea
        porce_comis = UsuariosTaquilla.find(enj.id_juega).comision.to_f
        monto_primario = enj.monto.to_f
        monto_secundario = (enj.monto.to_f / 2) - (((enj.monto.to_f / 2) * porce_comis) / 100)
        cuanto_gana = monto_primario + monto_secundario
        cuanto_gana_completo = monto_primario + (enj.monto.to_f / 2)
        cuanto_pierde = monto_primario / 2
        monto_gana_reporte = (enj.monto.to_f / 2)

        descripcion = "Gana la mitad #{enj.texto_jugada}"
        actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
        descripcion2 = "Pierde la mitad #{enj.texto_jugada}"
        actualizar_saldos(1, id_quien_pierde, descripcion2, cuanto_pierde, 2, enj.id, 2)
        busca_user = buscar_cliente_cajero(id_quien_gana)
        comis = enj.monto.to_f / 2
        if busca_user != '0'
          usrc = UsuariosTaquilla.find(id_quien_pierde)
          agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"

          set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_gana.to_f,
                         'Gana la mitad', comis, agente)
        end
        busca_user = buscar_cliente_cajero(id_quien_pierde)
        if busca_user != '0'
          usrc = UsuariosTaquilla.find(id_quien_gana)
          agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"

          set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_pierde.to_f,
                         'Pierde la mitad', comis, agente)
        end
        enj.update(activa: false, status2: 11, id_gana: id_quien_gana, premiada: true)
        PremiacionCaballosPuesto.create(moneda: 2, carrera_id: enj.carrera_id,
                                        id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                                        monto_pagado_completo: monto_gana_reporte, created_at: fecha_hora)
      end
    end

    def gana_lamitad_ind(enj, fecha_hora)
      id_quien_gana = enj.id_juega
      id_quien_pierde = enj.id_banquea
      porce_comis = UsuariosTaquilla.find(enj.id_juega).comision.to_f
      monto_primario = enj.monto.to_f
      monto_secundario = (enj.monto.to_f / 2) - (((enj.monto.to_f / 2) * porce_comis) / 100)
      cuanto_gana = monto_primario + monto_secundario
      cuanto_gana_completo = monto_primario + (enj.monto.to_f / 2)
      cuanto_pierde = monto_primario / 2
      monto_reporte = (enj.monto.to_f / 2)

      descripcion = "Gana la mitad #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      descripcion2 = "Pierde la mitad #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_pierde, descripcion2, cuanto_pierde, 2, enj.id, 2)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      comis = enj.monto.to_f / 2
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_gana.to_f,
                       'Gana la mitad', comis, agente)
      end
      busca_user = buscar_cliente_cajero(id_quien_pierde)
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_gana)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_pierde.to_f,
                       'Pierde la mitad', comis, agente)
      end
      enj.update(activa: false, status2: 11, id_gana: id_quien_gana, premiada: true)
      PremiacionCaballosPuesto.create(moneda: 2, carrera_id: enj.carrera_id,
                                      id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                                      monto_pagado_completo: monto_reporte, created_at: fecha_hora)
    end

    def pierde_lamitad(enj, fecha_hora)
      id_quien_gana = enj.id_banquea
      id_quien_pierde = enj.id_juega
      monto_primario = enj.monto.to_f
      porce_comis = UsuariosTaquilla.find(enj.id_banquea).comision.to_f
      monto_secundario = (enj.monto.to_f / 2) - (((enj.monto.to_f / 2) * porce_comis) / 100)
      cuanto_gana = monto_primario + monto_secundario
      cuanto_gana_completo = monto_primario + (enj.monto.to_f / 2)
      cuanto_pierde = monto_primario / 2
      monto_reporte = (enj.monto.to_f / 2)

      descripcion = "Gano la mitad Banqueo #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      descripcion2 = "Perdio la mitad Jugo #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_pierde, descripcion2, cuanto_pierde, 2, enj.id, 2)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      comis = enj.monto.to_f / 2
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"

        set_envios_api(1, busca_user, enj.tickets_detalle_id_banquea, enj.reference_id_banquea, cuanto_gana.to_f,
                       'Gana la mitad', comis, agente)
      end
      busca_user = buscar_cliente_cajero(id_quien_pierde)
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_gana)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_pierde.to_f,
                       'Pierde la mitad', comis, agente)
      end
      enj.update(activa: false, status2: 11, id_gana: id_quien_gana, premiada: true)
      PremiacionCaballosPuesto.create(moneda: 2, carrera_id: enj.carrera_id,
                                      id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                                      monto_pagado_completo: monto_reporte, created_at: fecha_hora)
    end

    def gana_completo(enj, fecha_hora)
      id_quien_gana = enj.id_juega
      id_quien_pierde = enj.id_banquea
      monto_primario = enj.id_propone == enj.id_juega ? enj.monto.to_f : enj.cuanto_gana_completo.to_f
      monto_secundario = enj.id_propone == enj.id_juega ? enj.cuanto_gana.to_f : (enj.monto.to_f - (enj.monto.to_f * UsuariosTaquilla.find(enj.id_juega).comision.to_f) / 100)
      cuanto_gana = monto_primario + monto_secundario
      cuanto_gana_completo = monto_primario + enj.cuanto_gana_completo.to_f
      monto_reporte = enj.cuanto_gana_completo.to_f

      descripcion = "Gano #{enj.texto_jugada}"
      actualizar_saldos(1, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      enj.update(activa: false, status: 2, status2: 8, id_gana: id_quien_gana, premiada: true, id_pierde: id_quien_pierde)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        comis = if enj.id_propone == enj.id_juega
                  enj.cuanto_gana_completo.to_f
                else
                  enj.monto.to_f
                end
        set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_gana.to_f,
                       "Gano #{enj.texto_jugada}", comis, agente)
      end
      PremiacionCaballosPuesto.create(moneda: 2, carrera_id: enj.carrera_id,
                                      id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                                      monto_pagado_completo: monto_reporte, created_at: fecha_hora)
    end

    def gana_completo_logros(enj, fecha_hora)
      id_quien_gana = enj.id_juega
      id_quien_pierde = enj.id_banquea
      # monto_primario = enj.monto.to_f
      # monto_secundario = enj.cuanto_gana.to_f
      monto_primario = enj.id_propone == enj.id_juega ? enj.monto.to_f : enj.cuanto_gana_completo.to_f
      monto_secundario = enj.id_propone == enj.id_juega ? enj.cuanto_gana.to_f : (enj.monto.to_f - (enj.monto.to_f * UsuariosTaquilla.find(enj.id_juega).comision.to_f) / 100)

      cuanto_gana = monto_primario + monto_secundario
      cuanto_gana_completo = monto_primario + enj.cuanto_gana_completo.to_f

      descripcion = "Gano #{enj.texto_jugada}"
      actualizar_saldos(2, id_quien_gana, descripcion, cuanto_gana, 2, enj.id, 2)
      enj.update(activa: false, status: 2, status2: 8, id_gana: id_quien_gana, premiada: true, id_pierde: id_quien_pierde)
      busca_user = buscar_cliente_cajero(id_quien_gana)
      if busca_user != '0'
        usrc = UsuariosTaquilla.find(id_quien_pierde)
        agente = "#{usrc.cobrador_id.to_s}-#{usrc.cliente_id}"
        comis = if enj.id_propone == enj.id_juega
                  enj.cuanto_gana_completo.to_f
                else
                  enj.monto.to_f
                end
        set_envios_api(1, busca_user, enj.tickets_detalle_id_juega, enj.reference_id_juega, cuanto_gana.to_f,
                       "Gano #{enj.texto_jugada}", comis, agente)
      end
      Premiacion.create(moneda: 2, carrera_id: enj.carrera_id, caballos_carrera_id: enj.caballos_carrera_id,
                        id_quien_juega: enj.id_juega, id_quien_banquea: enj.id_banquea, id_gana: id_quien_gana,
                        monto_pagado_completo: enj.cuanto_gana_completo.to_f, created_at: fecha_hora)
    end

    private

    def actualizar_saldos(producto, usuario_id, descripcion, monto, _moneda, enj_id, _tipo = 3)
      return 

      # monto_t = monto_local(usuario_id, monto)
      # # opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto, status: 0, moneda: 2, tipo: tipo)
      # if producto.to_i == 1
      #   opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto_t,
      #                                    status: 0, moneda: 2, tipo: 3, tipo_app: 1)
      #   unless descripcion[/Devolucion\/Retiro/i].present?                                 
      #     CarrerasPPuesto.create(premios_ingresado_id: @preming.id, operaciones_cajero_id: opcaj.id,
      #                           carrera_id: @preming.carrera_id, usuarios_taquilla_id: usuario_id, propuestas_caballos_puesto_id: enj_id, activo: true, status: 1)
      #   end
      # else
      #   opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto_t,
      #                                    status: 0, moneda: 2, tipo: 3, tipo_app: 3)
      #   unless descripcion[/Devolucion\/Retiro/i].present?                                 
      #     CarrerasPLogro.create(premios_ingresado_id: @preming.id, operaciones_cajero_id: opcaj.id,
      #                           carrera_id: @preming.carrera_id, usuarios_taquilla_id: usuario_id, propuestas_caballo_id: enj_id, activo: true, status: 1)
      #   end
      # end
    end

    # enjuego = Enjuego.where(created_at: fecha.to_time.all_da
  end
end
