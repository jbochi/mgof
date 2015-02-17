-- Returns Tukey's range for a given range:
-- http://en.wikipedia.org/wiki/Tukey%27s_range_test
local utils = require("utils")

local key = KEYS[1]
local k = ARGV[1] or 1.5

local raw_elements = redis.call('ZRANGEBYSCORE', key, '-inf', '+inf')
local elements = utils.time_series_to_values(raw_elements)
if #elements < 4 then
  return false
end

table.sort(elements)

local q1 = elements[math.floor(#elements / 4)]
local q3 = elements[math.floor(#elements / 4 * 3)]

local lt = q1 - k * (q3 - q1)
local ut = q3 + k * (q3 - q1)

return {tostring(lt), tostring(ut)}
