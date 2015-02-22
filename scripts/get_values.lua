local utils = require("utils")

local key = KEYS[1]
local start = ARGV[1]
local stop = ARGV[2]

local series = utils.time_series(key, start, stop)

for i = 1, #series do
  series[i] = {tostring(series[i][1]), tostring(series[i][2])}
end

return series
