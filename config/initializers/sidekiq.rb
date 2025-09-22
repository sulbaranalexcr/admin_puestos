require "sidekiq"
require "sidekiq/web"

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{Figaro.env.REDIS_HOST}:6379/1" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{Figaro.env.REDIS_HOST}:6379/1" }
end


Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  # Protect against timing attacks:
  # - See https://codahale.com/a-lesson-in-timing-attacks/
  # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
  # - Use & (do not use &&) so that it doesn't short circuit.
  # - Use digests to stop length information leaking
  # Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(user), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USER"])) &
  # Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(user), ::Digest::SHA256.hexdigest('superadmin')) &
  Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest('losvergatarios'))
end

