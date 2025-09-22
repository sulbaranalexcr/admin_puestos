# frozen_string_literal: true

module Unica
  # atajos utilidades
  class AtajosController < ApplicationController
    skip_before_action :verify_authenticity_token

    def activar_cierre_api
      if params[:activo].present?
        Hipodromo.update_all(cierre_api: true)
        render json: { 'status' => 'OK' }
      else
        render json: { 'status' => 'FAIL' }, status: 400
      end
    end
  end
end
