class ReintentarRetirarCaballosApiJob
  include Sidekiq::Worker

  def perform(args)
    agent = Mechanize.new
    header = { 'Content-Type' => 'application/json' }
    agent.post('https://admin-puesto.aposta2.com/unica/api/invalidate_horse', args.to_json, header)
  end
end
