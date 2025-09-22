module RetirarHelper
  def retirar_ejemplar(hip_id, carrera_id, caballo)
    caballos = [caballo]
    todos_caballos_nombre = true
    arreglo_enjuego = []
    arreglo_propuestas = []
    retirados_propuestas = []
    retirados_enjuego = []
    hipodromo = Hipodromo.find_by(abreviatura: hip_id)
    carrera_bus = Hipodromo.find_by(abreviatura: hip_id).jornada.last.carrera.find_by(numero_carrera: carrera_id)
    cantidad_caballos = CaballosCarrera.where(carrera_id: carrera_bus.id, retirado: false).count - 1
    retirar_tipo = []
    case cantidad_caballos
    when 5
      retirar_tipo = [15, 16, 17]
    when 4
      retirar_tipo = [11, 12, 13, 14, 15, 16, 17]
    when 3
      retirar_tipo = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    when 2
      retirar_tipo = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
    end
    carr = carrera_bus
    begin
      if caballos.count > 0
        caballos.each do |cab|
          buscar = CaballosCarrera.find_by(carrera_id: carr.id, numero_puesto: cab, retirado: false)
          next unless buscar.present?

          buscar.update(retirado: true)
          # ############enjuego###############
          enjuego = Enjuego.where(
            propuesta_id: Propuesta.where(caballo_id: buscar.id, activa: false, created_at: Time.now.all_day,
                                          status: 2).ids, activo: true, created_at: Time.now.all_day
          )
          if enjuego.present?
            enjuego.update_all(activa: false, status: 2, status2: 13, updated_at: DateTime.now)
            enjuego.each do |enj|
              enj.propuesta.update(status: 4, status2: 13)
              arreglo_enjuego << enj.id
              tipoenjuego = enj.propuesta.tipo_id.to_i
              tipo_apuesta_enj = TipoApuesta.find(enj.propuesta.tipo_id)
              id_quien_juega = enj.propuesta.usuarios_taquilla_id
              if enj.propuesta.accion_id == 1
                id_quien_banquea = enj.usuarios_taquilla_id
                monto_banqueado = (enj.propuesta.monto.to_f * tipo_apuesta_enj.forma_pagar.to_f)
                cuanto_juega = enj.monto.to_f
              else
                id_quien_juega = enj.usuarios_taquilla_id
                id_quien_banquea = enj.propuesta.usuarios_taquilla_id
                monto_banqueado = enj.propuesta.monto.to_f
                cuanto_juega = enj.monto.to_f
              end
              retirados_propuestas << enj.propuesta_id
              retirados_enjuego << enj.id
              moneda = enj.propuesta.moneda
              # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
              #                          descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
              # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
              #                          descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
            end
          end
          if retirar_tipo.length > 0
            enjuego = Enjuego.where(
              propuesta_id: Propuesta.where(carrera_id: carrera_id, activa: false, created_at: Time.now.all_day, status: 2,
                                            tipo_id: retirar_tipo).ids, activo: true, created_at: Time.now.all_day
            )
            if enjuego.present?
              enjuego.update_all(activa: false, status: 2, status2: 7, updated_at: DateTime.now)
              enjuego.each do |enj|
                enj.propuesta.update(status: 4, status2: 7)
                arreglo_enjuego << enj.id
                tipoenjuego = enj.propuesta.tipo_id.to_i
                tipo_apuesta_enj = TipoApuesta.find(enj.propuesta.tipo_id)
                if enj.propuesta.accion_id == 1
                  id_quien_juega = enj.propuesta.usuarios_taquilla_id
                  id_quien_banquea = enj.usuarios_taquilla_id
                  monto_banqueado = (enj.propuesta.monto.to_f * tipo_apuesta_enj.forma_pagar.to_f)
                  cuanto_juega = enj.monto.to_f
                else
                  id_quien_juega = enj.usuarios_taquilla_id
                  id_quien_banquea = enj.propuesta.usuarios_taquilla_id
                  monto_banqueado = enj.propuesta.monto.to_f
                  cuanto_juega = enj.monto.to_f
                end
                retirados_propuestas << enj.propuesta_id
                retirados_enjuego << enj.id

                moneda = enj.propuesta.moneda
                # OperacionesCajero.create(usuarios_taquilla_id: id_quien_juega,
                #                          descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: cuanto_juega, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
                # OperacionesCajero.create(usuarios_taquilla_id: id_quien_banquea,
                #                          descripcion: "Devuelto/Retiro: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: monto_banqueado, status: 0, moneda: enj.propuesta.moneda, tipo: 2)
              end
            end
          end

          # ############fin enjuego###########
          prupuestas = Propuesta.where(caballo_id: buscar.id, status: 1, created_at: Time.now.all_day)
          if prupuestas.present?
            prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
            prupuestas.each do |prop|
              prop.update(activa: false, status: 4, status2: 13) if (prop.status == 2) || (prop.status == 1)
              tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
              arreglo_propuestas << prop.id
              retirados_propuestas << prop.id
              # OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id,
              #                          descripcion: "Reverso/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
            end
          end

          next unless retirar_tipo.length > 0

          prupuestas = Propuesta.where(carrera_id: carrera_id, status: 1, created_at: Time.now.all_day,
                                       tipo_id: retirar_tipo)
          next unless prupuestas.present?

          prupuestas.update_all(activa: false, status: 4, updated_at: DateTime.now)
          prupuestas.each do |prop|
            prop.update(activa: false, status: 4, status2: 7) if (prop.status == 2) || (prop.status == 1)
            tipo_apuesta_enj = TipoApuesta.find(prop.tipo_id)
            arreglo_propuestas << prop.id
            retirados_propuestas << prop.id
            # OperacionesCajero.create(usuarios_taquilla_id: prop.usuarios_taquilla_id,
            #                          descripcion: "Devolucion/Retirado: #{Carrera.find(carr.id).jornada.hipodromo.nombre}/Carrera: #{carr.numero_carrera}/#{buscar.nombre}/#{tipo_apuesta_enj.nombre}", monto: prop.monto, status: 0, moneda: prop.moneda, tipo: 2)
          end
        end
      end
      [retirados_propuestas, retirados_enjuego]
    rescue StandardError => e
    end
  end

  def devolver_apuestas_caballo_deportes(hipodromo_id, carrera_id, tipo)
    # tipo   1 = carrera cerrada  2 = Retirar caballo
    case tipo
    when 1
      estatus = 1
    when 2
      estatus = [1, 2, 3]
    end

    ActiveRecord::Base.transaction do
      propuestas = PropuestasCaballo.where(hipodromo_id: hipodromo_id, carrera_id: carrera_id,
                                           created_at: Time.now.all_day, tipo_apuesta: 1, status: estatus)
      if propuestas.present?
        propuestas.each do |prop|
          estatus_anterior = prop.status
          if prop.status == 2
            prop.update(activa: false, status: 20, status2: 7)
          else
            prop.update(activa: false, status: 7, status2: 7)
          end
          if estatus_anterior == 1
            usuario = UsuariosTaquilla.find(prop.id_propone)
            monto = prop.monto.to_f.round(2)
            idioma = usuario.idioma
            tipo_logro = usuario.tipo_logro
            mensaje = mensaje_devolucion(idioma, tipo)
            actualizar_saldos(prop.id_propone.to_i, mensaje + " (#{prop.detalle_jugada(idioma, tipo_logro)})", monto,
                              2, prop.id, 2)
          else
            usuario_juega = UsuariosTaquilla.find(prop.id_juega)
            usuario_banquea = UsuariosTaquilla.find(prop.id_banquea)
            idioma1 = usuario_juega.idioma
            idioma2 = usuario_banquea.idioma
            tipo_logro1 = usuario_juega.tipo_logro
            tipo_logro2 = usuario_banquea.tipo_logro
            mensaje1 = mensaje_devolucion(idioma1, tipo)
            mensaje2 = mensaje_devolucion(idioma2, tipo)
            if prop.accion_id == 1
              monto_juega = prop.monto.to_f.round(2)
              monto_banquea = prop.cuanto_gana_completo.to_f.round(2)
            else
              monto_juega = prop.cuanto_gana_completo.to_f.round(2)
              monto_banquea = prop.monto.to_f.round(2)
            end
            actualizar_saldos(prop.id_juega.to_i, mensaje1 + " (#{prop.detalle_jugada(idioma1, tipo_logro1)})",
                              monto_juega, 2, prop.id, 2)
            actualizar_saldos(prop.id_banquea.to_i, mensaje2 + " (#{prop.detalle_jugada(idioma2, tipo_logro2)})",
                              monto_banquea, 2, prop.id, 2)
          end
        end
      end
    end
  end

  def actualizar_saldos(usuario_id, descripcion, monto, moneda, _enj_id, tipo = 3)
    # opcaj = OperacionesCajero.create(usuarios_taquilla_id: usuario_id, descripcion: descripcion, monto: monto,
    #                                  status: 0, moneda: moneda, tipo: tipo, tipo_app: 2)
    @ids_ganadores << usuario_id
  end
end
