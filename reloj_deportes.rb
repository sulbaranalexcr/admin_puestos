require "rufus-scheduler"
require_relative '/home/puestos/puestos/puestosadmin/config/environment'
#require_relative "config/environment"
ENV["TZ"] = "America/Caracas"
scheduler = Rufus::Scheduler.new
include ApplicationHelper


def devolver_propuestas(match_id)
  @cierrec_array_cajero = []
  @usuarios_interno_ganan = []
  ids_dia = PropuestasDeporte.where(match_id: match_id).map { |a| [a.id_juega] + [a.id_banquea] }.join(",").split(",").uniq.map! { |e| e.to_i }.reject { |k| k == 0 }
  if ids_dia.present?
    ids_dia = ids_dia.uniq
  else
    ids_dia = []
  end
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
end

scheduler.every "60s" do
  matchs = Match.select(:id, :local, :juego_id, :liga_id).where(activo: true).where("local <= now()")
  if matchs.present?
    @usuarios_interno_ganan = []

    @todos_ids = ActiveRecord::Base.connection.execute('select id,moneda_default_dolar as valor_moneda from usuarios_taquillas').as_json
    @ids_cajero_externop =  ActiveRecord::Base.connection.execute('select id,cliente_id, moneda_default_dolar as valor_moneda from usuarios_taquillas where usa_cajero_externo = true').as_json

    matchs.update_all(activo: false, updated_at: DateTime.now)
    matchs.each { |match|
      devolver_propuestas(match.id)
      if @usuarios_interno_ganan.length > 0
        saldos_enviar = UsuariosTaquilla.where(id: @usuarios_interno_ganan).pluck(:id, :saldo_usd)
        ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_SALDOS_PREMIOS", "data" => saldos_enviar } }
      end
      if @cierrec_array_cajero.length > 0
        PremiacionDeportesApiJob.perform_async @cierrec_array_cajero, match.liga_id, match.id, 4
      end
      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "CLOSE_MATCH", "match_id" => [match.id], "data_menu" => menu_deportes_helper(match.juego_id), "deporte_id" => match.juego_id  }}
    }
  end
end

scheduler.every "30s" do
  REDIS.set("reloj_deportes", Time.now.to_s)
  REDIS.close
end

scheduler.join
