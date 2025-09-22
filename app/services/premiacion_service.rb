# frozen_string_literal: true

module PremiacionService
  # clase para hipodromos
  class Api
    def self.carrera(id_carrera, hip_nyra, numero_carrera, carrera_id_nyra)
      PremiarCaballosApiJob.perform_async(id: id_carrera,
                                          premia_api: 1,
                                          hip_nyra: hip_nyra,
                                          numero_carrera: numero_carrera,
                                          carrera_id_nyra: carrera_id_nyra,
                                          cantidad_reintentar: 1)
    end
  end
end
