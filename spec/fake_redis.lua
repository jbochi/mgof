local redis_driver = require "redis"
local client = redis_driver.connect('127.0.0.1', 6379)
local redis = {
  call = function(command, ...)
    return client[command](client, ...)
  end
}

function unhashfy(obj, method)
  old_method = obj[method]
  obj[method] = function(...)
    local hash = old_method(...)
    local result = {}
    for k, v in pairs(hash) do
      result[#result + 1] = k
      result[#result + 1] = v
    end
    return result
  end
end

unhashfy(client, "hgetall")

return redis
