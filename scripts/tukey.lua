local key = KEYS[1]
local k = ARGV[1] or 1.5
local time_series_to_values = function(time_series)
  for i = 1, #time_series do
    local value = string.gsub(time_series[i], "%d+:", "")
    time_series[i] = tonumber(value)
  end
  return time_series
end
local elements = time_series_to_values(redis.call('ZRANGEBYSCORE', key, '-inf', '+inf'))
if #elements < 4 then
  return false
end
table.sort(elements)
local q1 = elements[math.floor(#elements / 4)]
local q3 = elements[math.floor(#elements / 4 * 3)]
local lt = q1 - k * (q3 - q1)
local ut = q3 + k * (q3 - q1)
return {tostring(lt), tostring(ut)}
