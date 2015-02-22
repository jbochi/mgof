local utils = require("utils")

local key = KEYS[1]
local start = ARGV[1]
local stop = ARGV[2]

return utils.get_values(key, start, stop)
