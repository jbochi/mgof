local utils = require("utils")

local key = KEYS[1]

for i = 1, #ARGV, 2 do
  local timestamp = tonumber(ARGV[i])
  local value = tonumber(ARGV[i + 1])
  utils.add_value(key, timestamp, value)
end
