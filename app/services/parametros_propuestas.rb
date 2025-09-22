# frozen_string_literal: true

module ParametrosPropuestas
  # clase para hipodromos
  # rubocop: disable Metrics/ClassLength
  class Condiciones
    TIPOA = {
      '1P' => 1, '1y2N' => 2, '2N' => 3, '2y2N' => 4, '2P' => 5, '2y3N' => 6, '3N' => 7, '3y3N' => 8,
      '3P' => 9, '3y4N' => 10, '4N' => 11, '4y4N' => 12, '4P' => 13, '4y5N' => 14, '5N' => 15,
      '5y5N' => 16, '5P' => 17, 'PaP' => 18, '10a9' => 19, '10a8' => 20, '10a7' => 21, '10a6' => 22,
      '10a5' => 23, '10a4' => 24, '10a3' => 25, '10a2' => 26
    }.freeze

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.cuatro_caballos(valor, vuelta)
      if valor.between?(1.3, 1.39)
        return [TIPOA['10a2'], TIPOA['10a5']] if vuelta == 1
        return [0, TIPOA['10a6']] if vuelta == 2
        return [0, TIPOA['10a7']] if vuelta == 3
      elsif valor.between?(1.4, 1.49)
        return [TIPOA['10a3'], TIPOA['10a6']] if vuelta == 1
        return [TIPOA['10a2'], TIPOA['10a7']] if vuelta == 2
        return [0, TIPOA['10a8']] if vuelta == 3
      elsif valor.between?(1.5, 1.59)
        return [TIPOA['10a4'], TIPOA['10a7']] if vuelta == 1
        return [TIPOA['10a3'], TIPOA['10a8']] if vuelta == 2
        return [TIPOA['10a2'], TIPOA['10a9']] if vuelta == 3
      elsif valor.between?(1.6, 1.69)
        return [TIPOA['10a5'], TIPOA['10a8']] if vuelta == 1
        return [TIPOA['10a4'], TIPOA['10a9']] if vuelta == 2
        return [TIPOA['10a3'], TIPOA['1P']] if vuelta == 3
      elsif valor.between?(1.7, 1.79)
        return [TIPOA['10a6'], TIPOA['10a9']] if vuelta == 1
        return [TIPOA['10a5'], TIPOA['1P']] if vuelta == 2
        return [TIPOA['10a4'], TIPOA['1y2N']] if vuelta == 3
      elsif valor.between?(1.8, 1.89)
        return [TIPOA['10a7'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a6'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a5'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(1.9, 1.99)
        return [TIPOA['10a8'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a7'], TIPOA['2N']] if vuelta == 2
        return [TIPOA['10a6'], TIPOA['2y2N']] if vuelta == 3
      elsif valor.between?(2, 2.39)
        return [TIPOA['1P'], TIPOA['2N']] if vuelta == 1
        return [TIPOA['10a9'], TIPOA['2y2N']] if vuelta == 2
        return [TIPOA['10a8'], TIPOA['2P']] if vuelta == 3
      elsif valor.between?(2.4, 2.59)
        return [TIPOA['1y2N'], TIPOA['2y2N']] if vuelta == 1
        return [TIPOA['1P'], TIPOA['2P']] if vuelta == 2
        return [TIPOA['10a9'], TIPOA['2y3N']] if vuelta == 3
      elsif valor.between?(2.6, 3.09)
        return [TIPOA['2N'], TIPOA['2P']] if vuelta == 1
        return [TIPOA['1y2N'], TIPOA['2y3N']] if vuelta == 2
        return [TIPOA['1P'], TIPOA['3N']] if vuelta == 3
      elsif valor.between?(3.1, 5.49)
        return [TIPOA['2y2N'], 0] if vuelta == 1
        return [TIPOA['2N'], 0] if vuelta == 2
        return [TIPOA['1y2N'], 0] if vuelta == 3
      elsif valor.between?(5.5, 6)
        return [TIPOA['2P'], 0] if vuelta == 1
        return [TIPOA['2y2N'], 0] if vuelta == 2
        return [TIPOA['2N'], 0] if vuelta == 3
      else
        [0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.cinco_caballos(valor, vuelta)
      if valor.between?(1.2, 1.29)
        return [0, TIPOA['10a3']] if vuelta == 1
        return [0, TIPOA['10a4']] if vuelta == 2
        return [0, TIPOA['10a5']] if vuelta == 3
      elsif valor.between?(1.3, 1.39)
        return [TIPOA['10a2'], TIPOA['10a4']] if vuelta == 1
        return [0, TIPOA['10a5']] if vuelta == 2
        return [0, TIPOA['10a6']] if vuelta == 3
      elsif valor.between?(1.4, 1.49)
        return [TIPOA['10a3'], TIPOA['10a5']] if vuelta == 1
        return [TIPOA['10a2'], TIPOA['10a6']] if vuelta == 2
        return [0, TIPOA['10a7']] if vuelta == 3
      elsif valor.between?(1.5, 1.59)
        return [TIPOA['10a4'], TIPOA['10a6']] if vuelta == 1
        return [TIPOA['10a3'], TIPOA['10a7']] if vuelta == 2
        return [TIPOA['10a2'], TIPOA['10a8']] if vuelta == 3
      elsif valor.between?(1.6, 1.69)
        return [TIPOA['10a5'], TIPOA['10a7']] if vuelta == 1
        return [TIPOA['10a4'], TIPOA['10a8']] if vuelta == 2
        return [TIPOA['10a3'], TIPOA['10a9']] if vuelta == 3
      elsif valor.between?(1.7, 1.79)
        return [TIPOA['10a6'], TIPOA['10a8']] if vuelta == 1
        return [TIPOA['10a5'], TIPOA['10a9']] if vuelta == 2
        return [TIPOA['10a4'], TIPOA['1P']] if vuelta == 3
      elsif valor.between?(1.8, 1.89)
        return [TIPOA['10a7'], TIPOA['10a9']] if vuelta == 1
        return [TIPOA['10a6'], TIPOA['1P']] if vuelta == 2
        return [TIPOA['10a5'], TIPOA['1y2N']] if vuelta == 3
      elsif valor.between?(1.9, 1.99)
        return [TIPOA['10a8'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a7'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a6'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(2, 2.29)
        return [TIPOA['1P'], TIPOA['2N']] if vuelta == 1
        return [TIPOA['10a9'], TIPOA['2y2N']] if vuelta == 2
        return [TIPOA['10a8'], TIPOA['2P']] if vuelta == 3
      elsif valor.between?(2.3, 2.49)
        return [TIPOA['1y2N'], TIPOA['2y2N']] if vuelta == 1
        return [TIPOA['1P'], TIPOA['2P']] if vuelta == 2
        return [TIPOA['10a9'], TIPOA['2y3N']] if vuelta == 3
      elsif valor.between?(2.5, 2.89)
        return [TIPOA['2N'], TIPOA['2P']] if vuelta == 1
        return [TIPOA['1y2N'], TIPOA['2y3N']] if vuelta == 2
        return [TIPOA['1P'], TIPOA['3N']] if vuelta == 3
      elsif valor.between?(2.9, 6)
        return [TIPOA['2y2N'], 0] if vuelta == 1
        return [TIPOA['2N'], 0] if vuelta == 2
        return [TIPOA['1y2N'], 0] if vuelta == 3
      else
        [0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.seis_caballos3(valor, vuelta)
      if valor.between?(1.2, 1.29)
        return [0, TIPOA['10a3']] if vuelta == 1
        return [0, TIPOA['10a4']] if vuelta == 2
        return [0, TIPOA['10a5']] if vuelta == 3
      elsif valor.between?(1.3, 1.39)
        return [TIPOA['10a2'], TIPOA['10a4']] if vuelta == 1
        return [0, TIPOA['10a5']] if vuelta == 2
        return [0, TIPOA['10a6']] if vuelta == 3
      elsif valor.between?(1.4, 1.49)
        return [TIPOA['10a3'], TIPOA['10a5']] if vuelta == 1
        return [TIPOA['10a2'], TIPOA['10a6']] if vuelta == 2
        return [0, TIPOA['10a7']] if vuelta == 3
      elsif valor.between?(1.5, 1.59)
        return [TIPOA['10a4'], TIPOA['10a6']] if vuelta == 1
        return [TIPOA['10a3'], TIPOA['10a7']] if vuelta == 2
        return [TIPOA['10a2'], TIPOA['10a8']] if vuelta == 3
      elsif valor.between?(1.6, 1.69)
        return [TIPOA['10a5'], TIPOA['10a7']] if vuelta == 1
        return [TIPOA['10a4'], TIPOA['10a8']] if vuelta == 2
        return [TIPOA['10a3'], TIPOA['10a9']] if vuelta == 3
      elsif valor.between?(1.7, 1.79)
        return [TIPOA['10a6'], TIPOA['10a8']] if vuelta == 1
        return [TIPOA['10a5'], TIPOA['10a9']] if vuelta == 2
        return [TIPOA['10a4'], TIPOA['1P']] if vuelta == 3
      elsif valor.between?(1.8, 1.89)
        return [TIPOA['10a7'], TIPOA['10a9']] if vuelta == 1
        return [TIPOA['10a6'], TIPOA['1P']] if vuelta == 2
        return [TIPOA['10a5'], TIPOA['1y2N']] if vuelta == 3
      elsif valor.between?(1.9, 1.99)
        return [TIPOA['10a8'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a7'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a6'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(2, 2.19)
        return [TIPOA['1P'], TIPOA['2N']] if vuelta == 1
        return [TIPOA['10a9'], TIPOA['2y2N']] if vuelta == 2
        return [TIPOA['10a8'], TIPOA['2P']] if vuelta == 3
      elsif valor.between?(2.2, 2.39)
        return [TIPOA['1y2N'], TIPOA['2y2N']] if vuelta == 1
        return [TIPOA['1P'], TIPOA['2P']] if vuelta == 2
        return [TIPOA['10a9'], TIPOA['2y3N']] if vuelta == 3
      elsif valor.between?(2.4, 2.49)
        return [TIPOA['2N'], TIPOA['2P']] if vuelta == 1
        return [TIPOA['1y2N'], TIPOA['2y3N']] if vuelta == 2
        return [TIPOA['1P'], TIPOA['3N']] if vuelta == 3
      elsif valor.between?(2.5, 3.09)
        return [TIPOA['2y2N'], TIPOA['2y3N']] if vuelta == 1
        return [TIPOA['2N'], TIPOA['3N']] if vuelta == 2
        return [TIPOA['1y2N'], 0] if vuelta == 3
      elsif valor.between?(3.1, 3.89)
        return [TIPOA['2P'], TIPOA['3N']] if vuelta == 1
        return [TIPOA['2y2N'], 0] if vuelta == 2
        return [TIPOA['2N'], 0] if vuelta == 3
      elsif valor.between?(3.9, 4.89)
        return [TIPOA['2y3N'], 0] if vuelta == 1
        return [TIPOA['2P'], 0] if vuelta == 2
        return [TIPOA['2y2N'], 0] if vuelta == 3
      elsif valor.between?(4.9, 5.49)
        return [TIPOA['3N'], 0] if vuelta == 1
        return [TIPOA['2y3N'], 0] if vuelta == 2
        return [TIPOA['2P'], 0] if vuelta == 3
      elsif valor.between?(5.5, 6)
        return [TIPOA['3y3N'], 0] if vuelta == 1
        return [TIPOA['3N'], 0] if vuelta == 2
        return [TIPOA['2y3N'], 0] if vuelta == 3
      else
        [0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.seis_caballos2(valor, vuelta)
      if valor.between?(1.2, 1.29)
        return [0, TIPOA['10a3']] if vuelta == 1
        return [0, TIPOA['10a4']] if vuelta == 2
        return [0, TIPOA['10a5']] if vuelta == 3
      elsif valor.between?(1.3, 1.39)
        return [TIPOA['10a2'], TIPOA['10a4']] if vuelta == 1
        return [0, TIPOA['10a5']] if vuelta == 2
        return [0, TIPOA['10a6']] if vuelta == 3
      elsif valor.between?(1.4, 1.49)
        return [TIPOA['10a3'], TIPOA['10a5']] if vuelta == 1
        return [TIPOA['10a2'], TIPOA['10a6']] if vuelta == 2
        return [0, TIPOA['10a7']] if vuelta == 3
      elsif valor.between?(1.5, 1.59)
        return [TIPOA['10a4'], TIPOA['10a6']] if vuelta == 1
        return [TIPOA['10a3'], TIPOA['10a7']] if vuelta == 2
        return [TIPOA['10a2'], TIPOA['10a8']] if vuelta == 3
      elsif valor.between?(1.6, 1.69)
        return [TIPOA['10a5'], TIPOA['10a7']] if vuelta == 1
        return [TIPOA['10a4'], TIPOA['10a8']] if vuelta == 2
        return [TIPOA['10a3'], TIPOA['10a9']] if vuelta == 3
      elsif valor.between?(1.7, 1.79)
        return [TIPOA['10a6'], TIPOA['10a8']] if vuelta == 1
        return [TIPOA['10a5'], TIPOA['10a9']] if vuelta == 2
        return [TIPOA['10a4'], TIPOA['1P']] if vuelta == 3
      elsif valor.between?(1.8, 1.89)
        return [TIPOA['10a7'], TIPOA['10a9']] if vuelta == 1
        return [TIPOA['10a6'], TIPOA['1P']] if vuelta == 2
        return [TIPOA['10a5'], TIPOA['1y2N']] if vuelta == 3
      elsif valor.between?(1.9, 1.99)
        return [TIPOA['10a8'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a7'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a6'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(2, 2.29)
        return [TIPOA['1P'], TIPOA['2N']] if vuelta == 1
        return [TIPOA['10a9'], TIPOA['2y2N']] if vuelta == 2
        return [TIPOA['10a8'], TIPOA['2P']] if vuelta == 3
      elsif valor.between?(2.3, 2.49)
        return [TIPOA['1y2N'], TIPOA['2y2N']] if vuelta == 1
        return [TIPOA['1P'], TIPOA['2P']] if vuelta == 2
        return [TIPOA['10a9'], TIPOA['2y3N']] if vuelta == 3
      elsif valor.between?(2.5, 2.59)
        return [TIPOA['2N'], TIPOA['2P']] if vuelta == 1
        return [TIPOA['1y2N'], TIPOA['2y3N']] if vuelta == 2
        return [TIPOA['1P'], TIPOA['3N']] if vuelta == 3
      elsif valor.between?(2.6, 3.09)
        return [TIPOA['2y2N'], TIPOA['2y3N']] if vuelta == 1
        return [TIPOA['2N'], TIPOA['3N']] if vuelta == 2
        return [TIPOA['1y2N'], 0] if vuelta == 3
      elsif valor.between?(3.1, 3.89)
        return [TIPOA['2P'], TIPOA['3N']] if vuelta == 1
        return [TIPOA['2y2N'], 0] if vuelta == 2
        return [TIPOA['2N'], 0] if vuelta == 3
      elsif valor.between?(3.9, 4.89)
        return [TIPOA['2y3N'], 0] if vuelta == 1
        return [TIPOA['2P'], 0] if vuelta == 2
        return [TIPOA['2y2N'], 0] if vuelta == 3
      elsif valor.between?(4.9, 6)
        return [TIPOA['3N'], 0] if vuelta == 1
        return [TIPOA['2y3N'], 0] if vuelta == 2
        return [TIPOA['2P'], 0] if vuelta == 3
      else
        [0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.seis_caballos1(valor, vuelta)
      if valor.between?(1.3, 1.39)
        return [TIPOA['10a2'], TIPOA['10a5']] if vuelta == 1
        return [0, TIPOA['10a6']] if vuelta == 2
        return [0, TIPOA['10a7']] if vuelta == 3
      elsif valor.between?(1.4, 1.49)
        return [TIPOA['10a3'], TIPOA['10a6']] if vuelta == 1
        return [TIPOA['10a2'], TIPOA['10a7']] if vuelta == 2
        return [0, TIPOA['10a8']] if vuelta == 3
      elsif valor.between?(1.5, 1.59)
        return [TIPOA['10a4'], TIPOA['10a7']] if vuelta == 1
        return [TIPOA['10a3'], TIPOA['10a8']] if vuelta == 2
        return [TIPOA['10a2'], TIPOA['10a9']] if vuelta == 3
      elsif valor.between?(1.6, 1.69)
        return [TIPOA['10a5'], TIPOA['10a8']] if vuelta == 1
        return [TIPOA['10a4'], TIPOA['10a9']] if vuelta == 2
        return [TIPOA['10a3'], TIPOA['1P']] if vuelta == 3
      elsif valor.between?(1.7, 1.79)
        return [TIPOA['10a6'], TIPOA['10a9']] if vuelta == 1
        return [TIPOA['10a5'], TIPOA['1P']] if vuelta == 2
        return [TIPOA['10a4'], TIPOA['1y2N']] if vuelta == 3
      elsif valor.between?(1.8, 1.89)
        return [TIPOA['10a7'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a6'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a5'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(1.9, 1.99)
        return [TIPOA['10a8'], TIPOA['PaP']] if vuelta == 1
        return [TIPOA['10a7'], TIPOA['1y2N']] if vuelta == 2
        return [TIPOA['10a6'], TIPOA['2N']] if vuelta == 3
      elsif valor.between?(2, 2.29)
        return [TIPOA['1P'], TIPOA['2N']] if vuelta == 1
        return [TIPOA['10a9'], TIPOA['2y2N']] if vuelta == 2
        return [TIPOA['10a8'], TIPOA['2P']] if vuelta == 3
      elsif valor.between?(2.3, 2.39)
        return [TIPOA['1y2N'], TIPOA['2y2N']] if vuelta == 1
        return [TIPOA['1P'], TIPOA['2P']] if vuelta == 2
        return [TIPOA['10a9'], TIPOA['2y3N']] if vuelta == 3
      elsif valor.between?(2.4, 2.69)
        return [TIPOA['2N'], TIPOA['2P']] if vuelta == 1
        return [TIPOA['1y2N'], TIPOA['2y3N']] if vuelta == 2
        return [TIPOA['1P'], TIPOA['3N']] if vuelta == 3
      elsif valor.between?(2.7, 3.89)
        return [TIPOA['2y2N'], TIPOA['2y3N']] if vuelta == 1
        return [TIPOA['2N'], TIPOA['3N']] if vuelta == 2
        return [TIPOA['1y2N'], 0] if vuelta == 3
      elsif valor.between?(3.9, 5.49)
        return [TIPOA['2P'], TIPOA['3N']] if vuelta == 1
        return [TIPOA['2y2N'], 0] if vuelta == 2
        return [TIPOA['2N'], 0] if vuelta == 3
      elsif valor.between?(5.5, 6)
        return [TIPOA['2y3N'], 0] if vuelta == 1
        return [TIPOA['2P'], 0] if vuelta == 2
        return [TIPOA['2y2N'], 0] if vuelta == 3
      else
        [0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/MethodLength
    # rubocop: disable Metrics/PerceivedComplexity
    # rubocop: disable Metrics/CyclomaticComplexity
    def self.parametros_ml(valor, monto, vuelta)
      if valor.between?(1.2, 1.99)
        return [valor - 0.1, valor + 0.2, monto] if vuelta == 1
        return [valor - 0.2, valor + 0.3, monto] if vuelta == 2
        return [valor - 0.3, valor + 0.4, monto] if vuelta == 3
      elsif valor.between?(2, 2.99)
        return [valor - 0.2, valor + 0.6, monto] if vuelta == 1
        return [valor - 0.3, valor + 0.8, monto] if vuelta == 2
        return [valor - 0.5, valor + 1.1, monto] if vuelta == 3
      elsif valor.between?(3, 3.99)
        monto *= 0.8
        return [valor - 0.3, valor + 1.2, monto] if vuelta == 1
        return [valor - 0.45, valor + 1.45, monto] if vuelta == 2
        return [valor - 0.6, valor + 1.7, monto] if vuelta == 3
      elsif valor.between?(4, 4.99)
        monto *= 0.7
        return [valor - 0.5, valor + 2, monto] if vuelta == 1
        return [valor - 0.7, valor + 2.3, monto] if vuelta == 2
        return [valor - 0.85, valor + 2.7, monto] if vuelta == 3
      elsif valor.between?(5, 5.99)
        monto *= 0.6
        return [valor - 0.7, valor + 3.2, monto] if vuelta == 1
        return [valor - 0.9, valor + 4.2, monto] if vuelta == 2
        return [valor - 1.05, valor + 5.2, monto] if vuelta == 3
      elsif valor.between?(6, 7.99)
        monto *= 0.4
        return [valor - 1, 0, monto] if vuelta == 1
        return [valor - 1.5, 0, monto] if vuelta == 2
        return [valor - 2.5, 0, monto] if vuelta == 3
      elsif valor.between?(8, 20)
        monto *= 0.4
        return [valor - 2, 0, monto] if vuelta == 1
        return [valor - 2.5, 0, monto] if vuelta == 2
        return [valor - 3, 0, monto] if vuelta == 3
      else
        [0, 0, 0]
      end
    end
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/PerceivedComplexity
    # rubocop: enable Metrics/CyclomaticComplexity
  end
  # rubocop: enable Metrics/ClassLength
end
