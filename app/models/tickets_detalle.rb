class TicketsDetalle < ApplicationRecord
  belongs_to :ticket
  attr_accessor :status_jugada
  scope :tickets_by_client, -> (client_id, date_start, date_end) { where(created_at: date_start.to_time.beginning_of_day..date_end.to_time.end_of_day, ticket_id: Ticket.tickets_by_client(client_id, date_start, date_end)).order(:id) }


  def propuestas
    search = { 'PropuestasCaballosPuesto' => self.propuesta_caballos_puesto_id.to_i,
               'PropuestasCaballo' => self.propuesta_caballo_id.to_i,
               'PropuestasDeporte' => self.propuesta_deporte_id.to_i }
    search = search.reject { |key, value| value.zero? }
    return { 'father' => nil, 'childrens' => nil } if search.blank?

    model_name = search.first[0]
    propuesta_id = search.first[1]
    propuesta_principal = PropuestasCaballosPuesto.find_by(id: propuesta_caballos_puesto_id)
    id_buscar = id_propone > 0 ? id_propone : id_toma
    fathers = if id_buscar == propuesta_principal.id_juega
               PropuestasCaballosPuesto.where(tickets_detalle_id_juega: id).order(:id)
             else
               PropuestasCaballosPuesto.where(tickets_detalle_id_banquea: id).order(:id)
             end
    childrens = []
    all_fathers = []
    
    fathers.select {|a| fathers.pluck(:id).exclude?(a.corte_id) }.each do |father|
      childrens = id_propone > 0 ? PropuestasCaballosPuesto.where(corte_id: father.id)&.order(:id) : []
      all_fathers << { 'data' => father, 'childrens' => childrens }
    end
    results = PremiosIngresado.where(carrera_id: propuesta_principal.carrera_id).last
    result = results.present? ? JSON.parse(results.caballos).select { |a| a['llegada'].to_i.positive? }.sort_by { |a| a['llegada'].to_i } : []

    { 'fathers' => all_fathers, 'results' => result }
  end

  def status_jugada(user_id)
    if propuesta_deporte_id.to_i > 0
      bus = PropuestasDeporte.find_by(id: propuesta_deporte_id.to_i)
    elsif propuesta_caballo_id.to_i > 0
      bus = PropuestasCaballo.find_by(id: propuesta_caballo_id.to_i)
    elsif propuesta_caballos_puesto_id.to_i > 0
      bus = PropuestasCaballosPuesto.find_by(id: propuesta_caballos_puesto_id.to_i)
    elsif propuesta_id.to_i > 0
      bus = Propuesta.find_by(id: propuesta_id.to_i)
    elsif enjuego_id.to_i > 0
      bus = Enjuego.find_by(enjuego_id.to_i)
    end
    if bus.present?
      bus.status_propuesta_banca(user_id)
    else
      ''
    end
  end

  def monto_cajero
    if propuesta_deporte_id.to_i > 0
      bus = PropuestasDeporte.find_by(id: propuesta_deporte_id.to_i)
    elsif propuesta_caballo_id.to_i > 0
      bus = PropuestasCaballo.find_by(id: propuesta_caballo_id.to_i)
    elsif propuesta_caballos_puesto_id.to_i > 0
      bus = PropuestasCaballosPuesto.find_by(id: propuesta_caballos_puesto_id.to_i)
    end
    if bus.present?
      mon_def = ticket.usuarios_taquilla.simbolo_moneda_default
      "#{bus.operaciones_cajero.monto.to_f * -1} #{mon_def}"
    else
      ''
    end
  end

  def hijas
    pro = Propuesta.find_by(id: propuesta_id)
    if pro.present?
      pro.hijas
    else
      false
    end
  end

  def origin_propuesta
    if propuesta_deporte_id.to_i > 0
      'PropuestasDeporte'
    elsif propuesta_caballo_id.to_i > 0
      'PropuestasCaballo'
    elsif propuesta_caballos_puesto_id.to_i > 0
      'PropuestasCaballosPuesto'
    elsif propuesta_id.to_i > 0
      'Propuesta'
    elsif enjuego_id.to_i > 0
      'Enjuego'
    end
  end
end
