
# redis: &redis
#   adapter: redis
#   url: "redis://#{Figaro.env.REDIS_HOST}:6379/1"

# production: *redis
# development: *redis
# test: *redis

# The constant below will represent ONE connection, present globally in models, controllers, views etc for the instance. No need to do Redis.new(host: Figaro.env.REDIS_HOST, port: 6379) everytime
#REDIS = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
# Redis.current = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)