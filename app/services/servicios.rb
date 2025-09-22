# frozen_string_literal: true

module Servicios
  # clase para cerrar carrera
  class Carreras
    def cerrar(id_carrera, user_id, notificar = true)
      carrera_id = id_carrera.to_i
      hip_id = Carrera.find(carrera_id).jornada.hipodromo.id
      CierreCarrera.create(hipodromo_id: hip_id, carrera_id: carrera_id, user_id: user_id)

      ActiveRecord::Base.connection.execute("update carreras set updated_at = now(), activo = false where id = #{carrera_id}")
      return unless notificar

      ActionCable.server.broadcast 'publicas_deporte_channel', { data: { 'tipo' => 'CERRAR_CARRERA_CABALLOS',
                                                                         'id' => carrera_id.to_i }}
    end
  end
end
