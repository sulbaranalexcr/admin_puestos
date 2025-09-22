class PremiarApiJob
  #< ApplicationJob
  #queue_as :default
  include Sidekiq::Worker

  def perform(args)
    prem = PremiarController.new
    prem.params = ActionController::Parameters.new(args)
    prem.premiar
  end
end
