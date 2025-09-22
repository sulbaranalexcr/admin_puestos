class Match < ApplicationRecord
  include ApplicationHelper
  belongs_to :juego, primary_key: "juego_id"
  belongs_to :liga, primary_key: "liga_id"
  has_many :propuestas_deportes
  after_update :actualizo
  after_create :nuevo_match

  def detalle_match
   deporte = Juego.find_by(juego_id: self.juego_id)
   liga = Liga.find_by(liga_id: self.liga_id)
   "#{deporte.nombre} Liga #{liga.nombre}/#{self.nombre}"
  end

  def nuevo_match
    ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_LIGA", "data_menu" => menu_deportes_helper(self.juego_id), "deporte_id" => self.juego_id, "liga_id" => self.liga_id }}
  end

  def actualizo
    datos = JSON.parse(self.data)
    logros_sistema = { "money_line" => [], "run_line" => [], "alta_baja" => [] }
    money_line = []
    run_line = []
    alta_baja = []
    if self.juego_id == 12
      if datos["money_line"].length > 0
        dat_money = datos["money_line"]["c"]
        money_line = [{ "o" => dat_money[1]["o"], "uk" => dat_money[1]["uk"], "us" => dat_money[1]["us"] }, { "o" => dat_money[2]["o"], "uk" => dat_money[2]["uk"], "us" => dat_money[2]["us"] }, { "o" => dat_money[0]["o"], "uk" => dat_money[0]["uk"], "us" => dat_money[0]["us"] }]
      else
        money_line = [false, false, false]
      end
      run_line = [false, false]
      if datos["alta_baja"].length > 0
        dat_altabaja = datos["alta_baja"]["c"]
        alta_baja = [{ "o" => dat_altabaja[0]["o"], "uk" => dat_altabaja[0]["uk"], "us" => dat_altabaja[0]["us"], "l" => dat_altabaja[0]["l"] }, { "o" => dat_altabaja[1]["o"], "uk" => dat_altabaja[1]["uk"], "us" => dat_altabaja[1]["us"], "l" => dat_altabaja[0]["l"] }]
      else
        alta_baja = [false, false]
      end
      logros_sistema = { "money_line" => money_line, "run_line" => [false, false], "alta_baja" => alta_baja }
    else
      if datos["money_line"].length > 0
        dat_money = datos["money_line"]["c"]
        money_line = [{ "o" => dat_money[0]["o"], "uk" => dat_money[0]["uk"], "us" => dat_money[0]["us"] }, { "o" => dat_money[1]["o"], "uk" => dat_money[1]["uk"], "us" => dat_money[1]["us"] }]
      else
        money_line = [false, false]
      end
      if datos["run_line"].length > 0
        dat_runline = datos["run_line"]["c"]
        run_line = [{ "o" => dat_runline[0]["o"], "uk" => dat_runline[0]["uk"], "us" => dat_runline[0]["us"], "l" => dat_runline[0]["l"] }, { "o" => dat_runline[1]["o"], "uk" => dat_runline[1]["uk"], "us" => dat_runline[1]["us"], "l" => dat_runline[0]["l"] }]
      else
        run_line = [false, false]
      end
      if datos["alta_baja"].length > 0
        dat_altabaja = datos["alta_baja"]["c"]
        alta_baja = [{ "o" => dat_altabaja[0]["o"], "uk" => dat_altabaja[0]["uk"], "us" => dat_altabaja[0]["us"], "l" => dat_altabaja[0]["l"] }, { "o" => dat_altabaja[1]["o"], "uk" => dat_altabaja[1]["uk"], "us" => dat_altabaja[1]["us"], "l" => dat_altabaja[0]["l"] }]
      else
        alta_baja = [false, false]
      end
      logros_sistema = { "money_line" => money_line, "run_line" => run_line, "alta_baja" => alta_baja }
    end
    if self.activo
      ActionCable.server.broadcast "publicas_deporte_channel", { data: { "tipo" => "UPDATE_MATCH_API", "match_id" => self.id, "logros" => logros_sistema }}
    end
    # Rails.logger.error "*********************** se actualizo un logro ******************"
  end

  def nombre_deporte
    Juego.find_by(juego_id: self.juego_id).nombre
  end

  def nombre_liga
    liga = Liga.find_by(liga_id: self.liga_id)
    liga.nombre if liga.present?
  end
end
