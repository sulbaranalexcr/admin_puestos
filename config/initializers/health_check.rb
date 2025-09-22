HealthMonitor.configure do |config|
  config.cache
  config.redis
  config.redis.configure do |redis_config|
    redis_config.url = 'redis://localhost:6379/1'
  end
end

