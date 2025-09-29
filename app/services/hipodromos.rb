# frozen_string_literal: true

module Hipodromos
  # clase para hipodromos
  class Carreras
    def self.connect_to_aws(type, params)
      Aws.config.update(region: 'us-east-2', credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']))
      client = Aws::Lambda::Client.new(region: 'us-east-2')
      req_payload = params
      payload = JSON.generate(req_payload)
      resp = client.invoke({ function_name: type, invocation_type: 'RequestResponse', log_type: 'None', payload: payload })
      JSON.parse(resp.payload.string)
    end

    def self.scratches
      data = connect_to_aws('hipodromos', { race_id: 0 })
      hip_ids = data['races'].pluck('iTSPEventCode').uniq
      racetracks = {}
      hip_ids.each do |hip|
        races_all = []
        extract_data_races(data, hip, races_all)
        # insert_racetracks(racetracks, hip, races_all)
      end
      racetracks
    end

    def self.cargar_hipodromo()
      data = connect_to_aws('hipodromos', { race_id: 0 })
      datos = []
      data['races'].group_by { |a| a['iTSPEventCode'] }.map { |a, b| b }.each do |rac|
        all = rac.pluck('iTSPEventCode', 'raceMeetingName', 'raceNumber', 'raceId')
        datos << { 'hip_id' => all.first.first, 'name' => all.first.second, 'races' => all.map { |a| { 'number' => a[2], 'id' => a[3] } } }
      end
      redis = Redis.new
      redis.set('carreras_nyra', datos.to_json)
      redis.expireat('carreras_nyra', (Time.now.end_of_day + 4.hours).to_i)
      { status: 'OK', message: 'Carreras cargadas correctamente' }
    rescue StandardError => e
      { status: 'FAILD', message: "Error al cargar las carreras: #{e.message}" }
    end

    def self.carreras_por_hipodromo(hipodromo, numero_carrera = nil)
      data = connect_to_aws('hipodromos', { race_id: 0 })
      datos = []
      data['races'].group_by { |a| a['iTSPEventCode'] }.map { |a, b| b }.each do |rac|
        all = rac.pluck('iTSPEventCode', 'raceMeetingName', 'raceNumber', 'raceId')
        datos << { 'hip_id' => all.first.first, 'name' => all.first.second, 'races' => all.map { |a| { 'number' => a[2], 'id' => a[3] } } }
      end
      buscar = datos.find { |a| a['hip_id'] == hipodromo }
      return { status: 'FAILD', message: 'No hay carreras para este hipódromo' } unless buscar.present?

      buscar = buscar['races'].find { |a| a['number'] == numero_carrera.to_i }['id'] if numero_carrera.present?
      buscar
    end

    def self.extract_data_races(data, hip, races_all)
      data['races'].select { |rc| rc['iTSPEventCode'] == hip }.pluck('raceId').each do |rc_id|
        scratches = []
        race = extract_race_data(data, rc_id)
        scratches << extract_scratches(data, rc_id)
        insert_race(races_all, scratches, rc_id, race)
      end
    end

    def self.extract_race_data(data, rc_id)
      data['races'].find { |rc| rc['raceId'] == rc_id }
    end

    def self.extract_scratches(data, rc_id)
      race = data['races'].find { |rc| rc['raceId'] == rc_id }
      return [] unless race.key?('raceTaggedValues')

      scratches = race['raceTaggedValues'].select { |sct| sct['name'] =~ /Scratched\.\d+/i }
      return [] unless scratches.count.positive?

      pluck_scratches(scratches)
    end

    def self.pluck_scratches(scratches)
      scratches.pluck('value')
               .map { |sct_a| [sct_a.split('|')[1], sct_a.split('|')[2]] }
    end

    def self.insert_racetracks(racetracks, hip, races_all)
      racetracks[hip] = races_all.sort_by { |rcs| rcs[:race_number] }
    end

    def self.insert_race(races_all, scratches, rc_id, race)
      scratches = if scratches.first.nil?
                    []
                  else
                    scratches.uniq(&:first).sort_by { |scrat| scrat[0] }
                  end
      races_all << { race_number: race['raceNumber'], race_id: rc_id, scratches: scratches.first, name: race['raceMeetingName'] }
    end

    def self.races_by_hipodromo(hipodromo, numero_carrera = nil)
      redis = Redis.new
      

      data = JSON.parse(redis.get('carreras_nyra'))
      buscar = data.find { |a| a['hip_id'] == hipodromo }
      return { status: 'FAILD', message: 'No hay carreras para este hipódromo' } unless buscar.present?

      buscar = buscar['races'].find { |a| a['number'] == numero_carrera.to_i }['id'] if numero_carrera.present?
      return buscar['races'] unless numero_carrera.present?

      buscar
    rescue StandardError => e
      []  
    end

    def self.results(race_id, nyra_race_id)
      data = connect_to_aws('results', { race_id: nyra_race_id })
      runners = data.key?('races') ? data['races'].first['runners'] : []
      arrivals = []
      scratches = []
      runners.each do |runner|
        arrivals << [runner['finishPosition'], runner['programNumber']] if runner.key?('finishPosition')
        scratches << runner['programNumber'] if runner['runnerStatus'].to_i == 2
      end

      return { status: 'FAILD', message: 'No hay resultados para esta carrera' } if arrivals.empty?
      return { status: 'OK', 'results' => arrivals, 'scratches' => scratches }

      arrivals = arrivals.sort[0..3]
      busca_ress = ResultadosNyra.find_by(carrera_id: race_id)
      if busca_ress.present?
        busca_ress.update(resultados: arrivals)
      else
        ResultadosNyra.create(carrera_id: race_id, resultados: arrivals)
      end
      [arrivals, scratches]
    end

    def self.extrac_nyra_id_race(hipodromo, numero_carrera)
      datos_carrera_nyra = CarrerasIdsNyra.find_by(codigo_nyra: hipodromo.codigo_nyra, created_at: Time.now.all_day)

      if datos_carrera_nyra.present?
        datos_carrera_nyra.ids_carrera.find { |a| a[0] == numero_carrera.to_i }[1]
      else
        data_aws_api = Hipodromos::Carreras.scratches
        Rails.logger.info "Datos AWS: #{data_aws_api}"
        codigos_carrera_nyra = data_aws_api[hipodromo.codigo_nyra].pluck(:race_number, :race_id)
        CarrerasIdsNyra.create(codigo_nyra: hipodromo.codigo_nyra, ids_carrera: codigos_carrera_nyra)
        codigos_carrera_nyra.find { |a| a[0] == numero_carrera.to_i }[1]
      end
    end
  end
end

# respaldo de amazon lambda
# hipodromos
# require 'json'
# require 'mechanize'

# def lambda_handler(event:, context:)
#   @agent = Mechanize.new
#   page = @agent.get('https://www.nyrabets.com/NYRA/default.aspx')
#   data = page.search('script').text.partition(/listRaces:/)[2].partition(/"returnCode"/)[0]
#   JSON.parse("#{data[0..-2]} }")
# end

# results
# require 'json'
# require 'mechanize'

# def lambda_handler(event:, context:)
#    @agent = Mechanize.new
#    carrera_id = event['race_id'].to_i
#    body= "{\"header\":{\"version\":2,\"fragmentLanguage\":\"Javascript\",\"fragmentVersion\":\"\",\"clientIdentifier\":\"nyra.1b\"},\"raceIds\":[#{carrera_id}]}"
#    page = @agent.post('https://brk0201-iapi-webservice.nyrabets.com/GetResults.aspx', { 'request' => body })
#    JSON.parse(page.body)
# end
