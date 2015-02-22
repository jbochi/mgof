local utils = require("utils")

local key = KEYS[1]
local timestamp = tonumber(ARGV[1])
local value = tonumber(ARGV[2])

return utils.add_value(key, timestamp, value)
