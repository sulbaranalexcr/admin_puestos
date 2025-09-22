class PropuestasCaballosPuesto < ApplicationRecord
  include ApplicationHelper

  belongs_to :grupo
  belongs_to :hipodromo
  belongs_to :carrera
  belongs_to :caballos_carrera
  belongs_to :tipo_apuesta
  belongs_to :operaciones_cajero, optional: true

  def status_propuesta
    text_status2(status2)
  end

  def tipo_ticket(user_id)
    if id_juega.to_i == user_id.to_i
      'Jugo '
    else
      'Banqueo '
    end
  end

  def monto_ticket(user_id)
    if accion_id == 1
      monto.to_f
    else
      cuanto_gana_completo.to_f
    end
  end

  def status_propuesta_banca(user_id)
    if [8, 9].include?(status2.to_i)
      if id_gana.to_i == user_id
        'Gano'
      else
        'Perdio'
      end
    elsif [11, 12].include?(status2.to_i)
      if id_gana.to_i == user_id
        'Gano la Mitad'
      else
        'Perdio la Mitad'
      end
    else
      text_status2(status2)
    end
  end

  def usa_igual_accion
    false
  end

  def usuarios_taquilla_id
    id_propone
  end

  def usuarios_taquilla_id_enjuego
    if id_propone == id_juega
      id_banquea
    else
      id_juega
    end
  end

  def tickets_detalle_id
    if id_propone == id_juega
      tickets_detalle_id_juega
    else
      tickets_detalle_id_banquea
    end
  end

  def hijas
    PropuestasCaballosPuesto.where(corte_id: id).order(:id) if status2 == 4
  end

  def self.calcular_ganancia_y_porcentaje_dia(dia)
    propuestas = where(status: 2, status2: [8, 9, 11, 12], created_at: dia.to_time.all_day)

    ganancia_total = propuestas.sum do |propuesta|
      # Verifica si el status2 es 11 o 12
      if [11, 12].include?(propuesta.status2)
        # Divide el monto correspondiente por 2
        if propuesta.id_gana == propuesta.id_propone
          propuesta.cuanto_gana_completo / 2.0
        else
          propuesta.monto / 2.0
        end
      else
        # Usa el monto completo sin dividir
        if propuesta.id_gana == propuesta.id_propone
          propuesta.cuanto_gana_completo
        else
          propuesta.monto
        end
      end
    end

    porcentaje = ganancia_total * 0.05

    { premios: ganancia_total.to_f, ganancia: porcentaje.to_f }
  end

  def self.calcular_ganancia_y_porcentaje(mes, anio)
    propuestas = where(status: 2, status2: [8, 9, 11, 12])
                 .where('extract(month from created_at) = ? AND extract(year from created_at) = ?', mes, anio)

    ganancia_total = propuestas.sum do |propuesta|
      # Verifica si el status2 es 11 o 12
      if [11, 12].include?(propuesta.status2)
        # Divide el monto correspondiente por 2
        if propuesta.id_gana == propuesta.id_propone
          propuesta.cuanto_gana_completo / 2.0
        else
          propuesta.monto / 2.0
        end
      else
        # Usa el monto completo sin dividir
        if propuesta.id_gana == propuesta.id_propone
          propuesta.cuanto_gana_completo
        else
          propuesta.monto
        end
      end
    end

    porcentaje = ganancia_total * 0.05

    { premios: ganancia_total.to_f, ganancia: porcentaje.to_f }
  end

  def self.calcular_ganancia_y_porcentaje_detallado(mes, anio)
    start_date = Date.new(anio, mes, 1)
    end_date = Date.new(anio, mes, 1).end_of_month
    array_dias = []
    (start_date..end_date).each do |fecha| 
      tasa_dia = HistorialTasa.where(moneda_id: 1, created_at: fecha.all_day).last.tasa_nueva
      propuestas = where(status: 2, status2: [8, 9, 11, 12])
                  .where(created_at: fecha.all_day)

      ganancia_total = propuestas.sum do |propuesta|
        # Verifica si el status2 es 11 o 12
        if [11, 12].include?(propuesta.status2)
          # Divide el monto correspondiente por 2
          if propuesta.id_gana == propuesta.id_propone
            propuesta.cuanto_gana_completo / 2.0
          else
            propuesta.monto / 2.0
          end
        else
          # Usa el monto completo sin dividir
          if propuesta.id_gana == propuesta.id_propone
            propuesta.cuanto_gana_completo
          else
            propuesta.monto
          end
        end
      end

      porcentaje = ganancia_total * 0.05
      data = { fecha: fecha.strftime('%d-%m-%Y'), monedas: [ { nombre: 'VES',  montos: { tasa: tasa_dia, premios: (ganancia_total.to_f * tasa_dia).round(2), ganancia: (porcentaje.to_f * tasa_dia).round(2) }},
                                                             { nombre: 'USD',  montos: { premios: ganancia_total.to_f.round(2), ganancia: porcentaje.to_f.round(2) }}]}
      array_dias << data
    end
    array_dias
  end

  def self.cuadre_paginas(fecha1, fecha2)
    grupos_all = []
    start_date = fecha1.to_time.beginning_of_day
    end_date = fecha2.to_time.end_of_day
    Grupo.all.each do |grp|
      paginas = UsuariosTaquilla.where(grupo_id: grp.id).pluck(:id_agente).uniq.reject { |a| a == '' }
      array_dias = []
      paginas_all = []
      ids = where(grupo_id: grp.id, status: 2, status2: [8, 9, 11, 12]).where(created_at: start_date..end_date).pluck(:id_juega, :id_banquea).flatten.uniq
      users_id = UsuariosTaquilla.where(id: ids).pluck(:id, :id_agente)
      paginas = users_id.map {|user| user[1]}.uniq.map {|use| { id: use, enviado: 0, recibido: 0, comision: 0}}

      propuestas = where(grupo_id: grp.id, status: 2, status2: [8, 9, 11, 12]).where(created_at: start_date..end_date)
      propuestas.each do |propuesta|
        enviado1  = 0.0
        recibido1 = 0.0 
        comision  = 0.0
        enviado2  = 0.0
        recibido2 = 0.0

        if [11, 12].include?(propuesta.status2)
          id_pierde = nil
          if propuesta.id_gana == propuesta.id_propone
            enviado1  = propuesta.monto.to_f
            recibido1 = (propuesta.monto.to_f + ((propuesta.cuanto_gana_completo / 2) - (((propuesta.cuanto_gana_completo / 2) * 5)/100))).to_f 
            comision  = (((propuesta.cuanto_gana_completo / 2) * 2.5)/100).to_f
          
            enviado2   = propuesta.cuanto_gana_completo.to_f
            recibido2  = propuesta.cuanto_gana_completo.to_f / 2.0
          else
            enviado1  = propuesta.cuanto_gana_completo.to_f
            recibido1 = propuesta.cuanto_gana_completo.to_f + (((propuesta.monto / 2) - (((propuesta.monto / 2 ) * 5)/100))).to_f
            comision  = (((propuesta.monto / 2) * 2.5)/100).to_f

            enviado2  = propuesta.monto.to_f
            recibido2  = propuesta.monto.to_f / 2.0
          end
          id_pierde  = propuesta.id_gana == propuesta.id_juega ? propuesta.id_banquea : propuesta.id_juega 
          web_gana = users_id.find { |a| a[0] == propuesta.id_gana }.last
          web_pierde = users_id.find { |a| a[0] == id_pierde }.last
          paginas.find { |pag| pag[:id] == web_gana }[:enviado] += enviado1
          paginas.find { |pag| pag[:id] == web_gana }[:recibido] += recibido1
          paginas.find { |pag| pag[:id] == web_gana }[:comision] += comision
          paginas.find { |pag| pag[:id] == web_pierde }[:enviado] += enviado2
          paginas.find { |pag| pag[:id] == web_pierde }[:recibido] += recibido2
          paginas.find { |pag| pag[:id] == web_pierde }[:comision] += comision
        else
          if propuesta.id_gana == propuesta.id_propone
            enviado1  = propuesta.monto.to_f
            recibido1 = (propuesta.monto.to_f + (propuesta.cuanto_gana_completo - ((propuesta.cuanto_gana_completo * 5)/100))).to_f 
            comision  = ((propuesta.cuanto_gana_completo * 2.5)/100).to_f 
          
            enviado2  = propuesta.cuanto_gana_completo.to_f
            recibido2 = 0.0
          else
            enviado1  = propuesta.cuanto_gana_completo.to_f
            recibido1 = (propuesta.cuanto_gana_completo.to_f + (propuesta.monto - ((propuesta.monto * 5)/100))).to_f
            comision  = ((propuesta.monto * 2.5)/100).to_f

            enviado2  = propuesta.monto.to_f
            recibido2 = 0.0
          end
          id_pierde  = propuesta.id_gana == propuesta.id_juega ? propuesta.id_banquea : propuesta.id_juega 
          web_gana = users_id.find { |a| a[0] == propuesta.id_gana }.last
          web_pierde = users_id.find { |a| a[0] == id_pierde }.last
          paginas.find { |pag| pag[:id] == web_gana }[:enviado] += enviado1
          paginas.find { |pag| pag[:id] == web_gana }[:recibido] += recibido1
          paginas.find { |pag| pag[:id] == web_gana }[:comision] += comision
          paginas.find { |pag| pag[:id] == web_pierde }[:enviado] += enviado2
          paginas.find { |pag| pag[:id] == web_pierde }[:comision] += comision
        end
      end
      grupos_all << { grupo_id: grp.id, nombre: grp.nombre, paginas: paginas }
    end
    grupos_all
  end

  def self.calcular_ganancia_y_porcentaje_detallado_monedas(mes, anio)
    start_date = Date.new(anio, mes, 1)
    end_date = Date.new(anio, mes, 1).end_of_month
    ultima_encontrada = nil
    array_all = []
    grupos = PropuestasCaballosPuesto.where(created_at: Time.now.all_month).pluck(:grupo_id).uniq
    grupos.each do |grupo_id|
      array_dias = []
      moneda_id = UsuariosTaquilla.where(grupo_id: grupo_id).last.moneda_default
      (start_date..end_date).each do |fecha| 
        histo_tasa = HistorialTasa.where(moneda_id: 1, created_at: fecha.all_day).last
        next unless histo_tasa.present?
        
        tasa_dia = histo_tasa.tasa_nueva
        propuestas = where(status: 2, status2: [8, 9, 11, 12], grupo_id: grupo_id)
                    .where(created_at: fecha.all_day)

        ganancia_total = propuestas.sum do |propuesta|
          # Verifica si el status2 es 11 o 12
          if [11, 12].include?(propuesta.status2)
            # Divide el monto correspondiente por 2
            if propuesta.id_gana == propuesta.id_propone
              propuesta.cuanto_gana_completo / 2.0
            else
              propuesta.monto / 2.0
            end
          else
            # Usa el monto completo sin dividir
            if propuesta.id_gana == propuesta.id_propone
              propuesta.cuanto_gana_completo
            else
              propuesta.monto
            end
          end
        end

        porcentaje = ganancia_total * 0.05
        premios_dia = moneda_id == 1 ? ganancia_total / tasa_dia : ganancia_total
        ganancia_dia = moneda_id == 1 ? porcentaje / tasa_dia : porcentaje
        data = { fecha: fecha.strftime('%d-%m-%Y'), tasa: tasa_dia, premios: premios_dia.to_f.round(2), ganancia: ganancia_dia.to_f.round(2) }
        array_dias << data
        ultima_encontrada = fecha
      end
      array_all << { grupo_id: grupo_id, dias: array_dias, total_premios: array_dias.sum { |d| d[:premios] }, total: array_dias.sum { |d| d[:ganancia] } }
    end
    array_all
  end
end
