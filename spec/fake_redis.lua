local redis_driver = require "redis"
local client = redis_driver.connect('127.0.0.1', 6379)
local redis = {
  call = function(command, ...)
    return client[command](client, ...)
  end
}

return redis
