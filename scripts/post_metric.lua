local utils = require("utils")

local key = KEYS[1]
local timestamp = ARGV[1]
local value = ARGV[2]

return utils.add_value(key, timestamp, value)
