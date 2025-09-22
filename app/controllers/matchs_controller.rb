class MatchsController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :json, :html
  before_action :set_match, only: %i[show edit update]
  before_action :check_user_auth, only: %i[show index]
  before_action :seguridad_cuentas, only: %i[index edit new]

  def index
    # m1 = Match.where("local >= now()").order(:local)
    # m2 = Match.where(local: Time.now.all_day).where("local < now()").order(:local)
    # @matchs = m1 + m2
    @matchs = Match.where(local: Time.now.all_day).order(:local)
  end

  def show; end

  def new
    funciona = false
    @match_nuevo = 0
    while funciona == false
      @match_nuevo = SecureRandom.random_number(100_000_000)
      busca_match = Match.find_by(match_id: @match_nuevo)
      funciona = true unless busca_match.present?
    end

    flash.clear unless session['existe'].present?
    @match_nuevo1 = @match_nuevo.to_s + '1'
    @match_nuevo2 = @match_nuevo.to_s + '2'
    @match_nuevo3 = @match_nuevo.to_s + '3'
    @match = Match.new
    @url = matchs_path
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

  def create
    session['existe'] = false
    usa_altabaja = params[:usa_altabaja].to_i
    deporte_id = params[:juego_id].to_i
    liga_id = params[:liga_id].to_i
    empate = params[:empate]
    usa_empate = !(params[:empate].to_i == 0)
    eq1 = params[:equipo1]
    eq2 = params[:equipo2]
    hora = params[:hora]
    if (deporte_id == 0) || (liga_id == 0)
      ActionCable.server.broadcast 'web_notifications_banca_channel',
                                   { data: { 'tipo' => 400, 'msg' => 'Debe seleccionar deporte y liga.' }}
      return
    end
    @match_nuevo = SecureRandom.random_number(100_000_000)
    busca_match = Match.find_by(match_id: @match_nuevo)

    if busca_match.present?
      ActionCable.server.broadcast 'web_notifications_banca_channel',
                                   { data: { 'tipo' => 400, 'msg' => 'Existe un match con ese id.' }}
      return
    end
    buscar_jornada = JornadaDeporte.find_by(juego_id: deporte_id, liga_id: liga_id,
                                            fecha: hora.to_time.beginning_of_day..hora.to_time.end_of_day)
    unless buscar_jornada.present?
      buscar_jornada = JornadaDeporte.create(juego_id: deporte_id, liga_id: liga_id, fecha: hora)
    end

    id_temp = SecureRandom.random_number(10_000_000)
    if deporte_id.to_i == 12
      eq1id = id_temp
      eq2id = id_temp + 1
      eq3id = id_temp + 2
      money_data = [
        { 'i' => eq3id.to_i, 't' => 'Draw', 'o' => convertir_logro('us', params[:emoneyline3]), 'uk' => '',
          'us' => params[:emoneyline3].to_i }, { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:moneyline3]), 'uk' => '', 'us' => params[:moneyline3].to_i }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:moneyline23]), 'uk' => '', 'us' => params[:moneyline23].to_i }
      ]
      runline_data = []
    else
      eq1id = params[:match_manual1]
      eq2id = params[:match_manual2]
      money_data = [
        { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:moneyline3]), 'uk' => '',
          'us' => params[:moneyline3].to_i }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:moneyline23]), 'uk' => '', 'us' => params[:moneyline23].to_i }
      ]
      if params[:runline3].to_i == 0 || params[:runline23].to_i == 0
        runline_objeto = []
      else
        runline_data = [
          { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:runline3]), 'uk' => '', 'us' => params[:runline3].to_i,
            'l' => params[:dadas1].to_f }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:runline23]), 'uk' => '', 'us' => params[:runline23].to_i, 'l' => (params[:dadas1].to_f * - 1) }
        ]
        runline_objeto = { 'i' => @match_nuevo, 't' => 'Spread', 'x' => 'ML', 'c' => runline_data }
      end
    end
    if usa_altabaja.to_i == 1
      altabaja_data = [
        { 'i' => 1, 't' => 'Alta', 'o' => convertir_logro('us', params[:altabaja3]), 'uk' => '', 'us' => params[:altabaja3].to_i,
          'l' => params[:dadas21].to_f }, { 'i' => 2, 't' => 'Baja', 'o' => convertir_logro('us', params[:altabaja23]), 'uk' => '', 'us' => params[:altabaja23].to_i, 'l' => params[:dadas21].to_f }
      ]
      altabaja_objeto = { 'i' => @match_nuevo, 't' => 'Totals', 'x' => 'PS', 'c' => altabaja_data }
    else
      altabaja_objeto = []
    end

    data_final_match = {
      'match_id' => @match_nuevo,
      'match' => eq1 + ' vs ' + eq2,
      'deporte_id' => deporte_id,
      'liga_id' => liga_id,
      'local' => hora,
      'utc' => hora.to_time.utc,
      'money_line' =>
            { 'i' => @match_nuevo,
              't' => 'Straight Up',
              'x' => 'SM',
              'c' => money_data },
      'run_line' => runline_objeto,
      'alta_baja' => altabaja_objeto
    }

    @match = Match.create(match_id: @match_nuevo, nombre: eq1 + ' vs ' + eq2, local: hora, utc: hora.to_time.utc,
                          data: data_final_match.to_json, juego_id: deporte_id, liga_id: liga_id, activo: true, status: 1, jornada_id: buscar_jornada.id, usa_empate: usa_empate, id_base: 0,
                          show_next: params[:show_next])

    flash[:notice] = 'Match creado.'
    respond_to do |format|
      format.html { redirect_to '/matchs' }
      format.json { head :no_content }
    end
  end

  def edit
    @match = Match.find(params[:id])
    @deporte = Juego.find_by(juego_id: Liga.find_by(liga_id: @match.liga_id).juego_id)
    @ligas = Liga.where(juego_id: @match.juego_id)
    @match_match = JSON.parse(@match.data)
    @es_empate = @match.usa_empate
    @usa_empate = @match.usa_empate
    @url = match_path(@match)
    if @match.juego_id.to_i != 12
      @usa_altabaja = @match_match['alta_baja'].length > 0 ? 1 : 2
      @match_nuevo1 = @match_match['money_line']['c'][0]['i'].to_i
      @match_nuevo2 = @match_match['money_line']['c'][1]['i'].to_i
    else
      @usa_altabaja = @match_match['alta_baja'].length > 0 ? 1 : 2
      @match_nuevo1 = @match_match['money_line']['c'][1]['i'].to_i
      @match_nuevo2 = @match_match['money_line']['c'][2]['i'].to_i
      @match_nuevo3 = @match_match['money_line']['c'][0]['i'].to_i
    end
  end

  def update
    session['existe'] = false
    usa_altabaja = params[:usa_altabaja].to_i
    deporte_id = params[:juego_id].to_i
    liga_id = params[:liga_id].to_i
    empate = params[:empate]
    usa_empate = !(params[:empate].to_i == 0)
    eq1 = params[:equipo1]
    eq2 = params[:equipo2]
    hora = params[:hora]

    if (deporte_id == 0) || (liga_id == 0)
      ActionCable.server.broadcast 'web_notifications_banca_channel',
                                   { data: { 'tipo' => 400, 'msg' => 'Debe seleccionar deporte y liga.' }}
      return
    end
    busca_match = Match.find(@match.id)
    data_ant = JSON.parse(busca_match.data)

    buscar_jornada = JornadaDeporte.find_by(juego_id: deporte_id, liga_id: liga_id,
                                            fecha: hora.to_time.beginning_of_day..hora.to_time.end_of_day)

    id_temp = SecureRandom.random_number(10_000_000)
    if deporte_id.to_i == 12
      eq1id = data_ant['money_line']['c'][1]['i']
      eq2id = data_ant['money_line']['c'][2]['i']
      eq3id = data_ant['money_line']['c'][0]['i']
      money_data = [
        { 'i' => eq3id.to_i, 't' => 'Draw', 'o' => convertir_logro('us', params[:emoneyline3]), 'uk' => '',
          'us' => params[:emoneyline3].to_i }, { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:moneyline3]), 'uk' => '', 'us' => params[:moneyline3].to_i }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:moneyline23]), 'uk' => '', 'us' => params[:moneyline23].to_i }
      ]
      runline_data = []
    else
      eq1id = data_ant['money_line']['c'][0]['i']
      eq2id = data_ant['money_line']['c'][1]['i']
      money_data = [
        { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:moneyline3]), 'uk' => '',
          'us' => params[:moneyline3].to_i }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:moneyline23].to_i), 'uk' => '', 'us' => params[:moneyline23].to_i }
      ]
      if params[:runline3].to_i == 0 || params[:runline23].to_i == 0
        runline_objeto = []
      else
        runline_data = [
          { 'i' => eq1id.to_i, 't' => eq1, 'o' => convertir_logro('us', params[:runline3]), 'uk' => '', 'us' => params[:runline3].to_i,
            'l' => params[:dadas1].to_f }, { 'i' => eq2id.to_i, 't' => eq2, 'o' => convertir_logro('us', params[:runline23]), 'uk' => '', 'us' => params[:runline23].to_i, 'l' => (params[:dadas1].to_f * - 1) }
        ]
        runline_objeto = { 'i' => @match_nuevo.to_i, 't' => 'Spread', 'x' => 'ML', 'c' => runline_data }
      end
    end
    if usa_altabaja.to_i == 1
      altabaja_data = [
        { 'i' => 1, 't' => 'Alta', 'o' => convertir_logro('us', params[:altabaja3]), 'uk' => '', 'us' => params[:altabaja3].to_i,
          'l' => params[:dadas21].to_f }, { 'i' => 2, 't' => 'Baja', 'o' => convertir_logro('us', params[:altabaja23]), 'uk' => '', 'us' => params[:altabaja23].to_i, 'l' => params[:dadas21].to_f }
      ]
      altabaja_objeto = { 'i' => @match_nuevo, 't' => 'Totals', 'x' => 'PS', 'c' => altabaja_data }
    else
      altabaja_objeto = []
    end

    data_final_match = {
      'match_id' => @match_nuevo,
      'match' => eq1 + ' vs ' + eq2,
      'deporte_id' => deporte_id,
      'liga_id' => liga_id,
      'local' => hora,
      'utc' => hora.to_time.utc,
      'money_line' =>
            { 'i' => @match_nuevo,
              't' => 'Straight Up',
              'x' => 'SM',
              'c' => money_data },
      'run_line' => runline_objeto,
      'alta_baja' => altabaja_objeto
    }
    busca_match.update(nombre: eq1 + ' vs ' + eq2, local: hora, utc: hora.to_time.utc,
                       data: data_final_match.to_json, juego_id: deporte_id, liga_id: liga_id, activo: true, status: 1, jornada_id: buscar_jornada.id, usa_empate: usa_empate,
                       show_next: params[:show_next])
    @match = busca_match

    flash[:notice] = 'Match actualizado.'
    respond_to do |format|
      format.html { redirect_to '/matchs' }
      format.json { head :no_content }
    end
  end

  def destroy
    jue = Match.find_by(id: params[:id])
    jue.destroy if jue.present?
    respond_to do |format|
      format.html { redirect_to '/matchs' }
      format.json { head :no_content }
    end
  end

  def buscar_liga
    @ligas = Liga.where(juego_id: params[:id], activo: true)
    render partial: 'matchs/ligas', layout: false
  end

  def cerrar_match
    juegos_ant = Match.find(params[:id])
    match_id = juegos_ant.match_id
    juegos_ant.update(activo: false)
    ActionCable.server.broadcast 'publicas_deporte_channel',
                                { data: { 'tipo' => 'CLOSE_MA}TCH', 'match_id' => [params[:id]], 'data_menu' => menu_deportes_helper(juegos_ant.juego_id),
                                         'deporte_id' => juegos_ant.juego_id }}
    prupuestas = PropuestasDeporte.where(match_id: params[:id], activa: true, created_at: Time.now.all_day)
    if prupuestas.present?
      prupuestas.update_all(activa: false, status: 4, status2: 7, updated_at: DateTime.now)
      prupuestas.each do |prop|
        OperacionesCajero.create(usuarios_taquilla_id: prop.id_propone,
                                 descripcion: "Reverso por juego cerrado: #{prop.accion_id == 1 ? 'Jugo' : 'Banqueo'} #{prop.tipo_nombre} #{prop.match_nombre} (#{prop.logro.to_i})", monto: prop.monto, status: 0, moneda: 2, tipo: 2, tipo_app: 2)
      end
    end
  end

  private def set_match
    @match = Match.find(params[:id])
  end

  private

  def match_params
    params.require(:match).permit(:match_id, :liga_id, :nombre, :nombre_largo)
  end
end
