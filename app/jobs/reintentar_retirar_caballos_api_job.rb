class ReintentarRetirarCaballosApiJob
  include Sidekiq::Worker

  def perform(args)
    agent = Mechanize.new
    header = { 'Content-Type' => 'application/json' }
    agent.post('http://localhost:4000/api/invalidate_horse', args.to_json, header)
  end
end
