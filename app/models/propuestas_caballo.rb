class PropuestasCaballo < ApplicationRecord
  include ApplicationHelper

  belongs_to :caballos_carrera
  belongs_to :operaciones_cajero, optional: true

  def usa_igual_accion
    false
  end

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

  def detalle_jugada(idioma, tipo_logro)
    mensaje = ''
    caballos_bus = caballos_carrera

    mensaje += caballos_carrera.carrera.jornada.hipodromo.nombre + ' / '
    mensaje += 'Carrera ' + caballos_carrera.carrera.numero_carrera + ' / '
    mensaje += caballos_bus.numero_puesto + '-' + caballos_bus.nombre + ' / '
    mensaje += if tipo_logro == 'us'
                 (logro > 0) && (logro != 100) ? ('+' + logro.to_i.to_s) : logro.to_i.to_s
               else
                 convertir_logro(idioma, logro.to_i).to_s
               end
  end

  def convertir_logro(_tipo, logro)
    logro = logro.to_i
    resultado = 0
    if logro > 0
      (1.to_f + (logro.to_f / 100.to_f)).round(4)
    else
      (1.to_f - (100.to_f / logro.to_f)).round(4)
    end
  end

  def hijas
    PropuestasCaballo.where(corte_id: id).order(:id) if status2 == 4
  end
end
