module Unica
  class QuerysController < ApplicationController
    skip_before_action :verify_authenticity_token

    def relacion_tickets_detalle
      ticket = TicketsDetalle.find_by(gticket: params[:t_id])
      if ticket.present?
        user_taq = ticket.ticket.usuarios_taquilla
        id_usuario = user_taq.id.to_i
        valor_dolar = user_taq.moneda_default_dolar.to_f
        simbolo = user_taq.simbolo_moneda_default
        datos = ticket.propuesta_caballos_puesto_id > 0 ? ticket.propuestas : []
        render json: { 'status' => 'success', 'details' => generate_data(ticket, datos) }
      else
        render json: { 'status' => 'faild', 'mensaje' => 'Ticket no existe.' }, status: 400
      end
    end

    def generate_data(ticket_det, datos)
      # return datos
      data = []
      hijos = []
      datos['fathers'].each  do |father|
        user = ticket_det.ticket.usuarios_taquilla
        tipo = father['data']['id_juega'] == user.id ? 'Jugo' : 'Banqueo'
        find_prop = PropuestasCaballosPuesto.find_by(id: father['data']['id'])
        status = find_prop.status_propuesta_banca(user.id)
        monto = if father['data']['id_propone'] == user.id && father['data']['id_gana'] == user.id
                  father['data']['monto'] + father['data']['cuanto_gana'] 
                elsif father['data']['id_propone'] == user.id && father['data']['id_gana'] != user.id  
                  father['data']['monto'] 
                elsif father['data']['id_propone'] != user.id && father['data']['id_gana'] == user.id   
                  base = father['data']['monto'].to_f
                  father['data']['cuanto_gana_completo'] + (base - ((base * user.comision) /100 ))
                elsif father['data']['id_propone'] != user.id && father['data']['id_gana'] != user.id   
                  father['data']['cuanto_gana_completo']
                end  
        monto = monto.to_f * user.moneda_default_dolar.to_f
        transaction = father['data']['id_juega'] == user.id ? father['data']['tickets_detalle_id_juega'] : father['data']['tickets_detalle_id_banquea']
        reference = father['data']['id_juega'] == user.id ? father['data']['reference_id_juega'] : father['data']['reference_id_banquea'] 
        data_father = { bet: "#{tipo} #{father['data']['texto_jugada']}", amount: monto, status: status, time: ticket_det.created_at.strftime('%d/%m/%Y %H:%M'), transaction_id: transaction, reference_id: reference }
        father['childrens'].each do |child|
          monto = if child['id_propone'] == user.id && child['id_gana'] == user.id
                    child['monto'] + child['cuanto_gana'] 
                  elsif child['id_propone'] == user.id && child['id_gana'] != user.id  
                    child['monto'] 
                  elsif child['id_propone'] != user.id && child['id_gana'] == user.id   
                    base = child['monto'].to_f
                    child['cuanto_gana_completo'] + (base - ((base * user.comision) /100 ))
                  elsif child['id_propone'] != user.id && child['id_gana'] != user.id   
                    child['cuanto_gana_completo']
                  end  
          monto = monto.to_f * user.moneda_default_dolar.to_f
          find_prop = PropuestasCaballosPuesto.find_by(id: child['id'])
          status = find_prop.status_propuesta_banca(user.id)
          transaction = child['id_juega'] == user.id ? child['tickets_detalle_id_juega'] : child['tickets_detalle_id_banquea']
          reference = child['id_juega'] == user.id ? child['reference_id_juega'] : child['reference_id_banquea'] 
          hijos << { bet: "#{tipo} #{child['texto_jugada']}", amount: monto, status: status, transaction_id: transaction, reference_id: reference }
        end
        data << { user_id: user.cliente_id, main: data_father, childrens: hijos}
      end
      data
    end
  end
end