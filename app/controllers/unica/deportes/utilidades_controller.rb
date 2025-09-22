module Unica
  module Deportes
    class UtilidadesController < ApplicationController

      def verificar_deportes
        fecha = (Time.now - 1.day).beginning_of_day..Time.now.end_of_day
        ids = PremiosIngresadosDeporte.where(created_at: fecha).pluck(:match_id)
        ids_ligas = Liga.where(activo: true).pluck(:liga_id)
        @matchs = Match.where(liga_id: ids_ligas, local: fecha, activo: false).where.not(id: ids).order(:liga_id, :local)
      end
    end
  end
end