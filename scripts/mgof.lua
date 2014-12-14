-- mgof algorithm adapted from http://www.hpl.hp.com/techreports/2011/HPL-2011-8.pdf

local key = KEYS[1]
local n_bins = tonumber(ARGV[1]) or 10      -- number of bins: between 1 and 10
local w_size = tonumber(ARGV[2]) or 60      -- window size
local confidence = tonumber(ARGV[3]) or 99  -- test confidence (95 or 99)
local c_th = tonumber(ARGV[4]) or 1         -- c_th is a threshold
                                            --   to determine if a hypothesis has
                                            --   occurred frequently enough
local debug_script = string.lower(ARGV[5]) == "true"  -- to debug or not


local chi_square = {[99]={6.63, 9.21, 11.34, 13.28, 15.09, 16.81, 18.48, 20.09, 21.67},
                    [95]={3.84, 5.99,  7.81,  9.49, 11.07, 12.59, 14.07, 15.51, 16.92}}

local debug = function(...)
  if debug_script then
    print(...)
  end
end

local create_bin_classifier = function(time_series, n_bins)
  local min
  local max
  for i = 1, #time_series do
    if min == nil or time_series[i] < min then
      min = time_series[i]
    end
    if max == nil or time_series[i] > max then
      max = time_series[i]
    end
  end
  local step_size = (max - min) / n_bins
  local classifier = function(value)
    return math.max(1, math.ceil((value - min) / step_size))
  end
  debug("MAX", "MIN", "STEP")
  debug(max, min, step_size)
  return classifier
end

local distribution = function(time_series, n_bins, classifier, offset, size)
  offset = offset or 1
  size = size or (#time_series - offset + 1)
  local p = {}
  for i = 1, n_bins do
    p[i] = 0
  end
  for i = offset, offset + size - 1 do
    local bin = classifier(time_series[i])
    p[bin] = p[bin] + 1
  end
  for i = 1, n_bins do
    p[i] = p[i] / size
  end
  return p
end

local time_series_to_values = function(time_series)
  for i = 1, #time_series do
    local value = string.gsub(time_series[i], "%d+:", "")
    time_series[i] = tonumber(value)
  end
  return time_series
end

local relative_entropy = function(q, p)
  local total = 0
  debug("bin", "q[i]", "p[i]", "running sum")
  for i = 1, #q do
    if q[i] > 0 then
      total = total + q[i] * math.log(q[i] / p[i])
    end
    debug(i, tostring(q[i]), tostring(p[i]), tostring(total))
  end
  return total
end

local likelihood_ratio = function(p_observed, p)
  local n = #p_observed
  return n * relative_entropy(p_observed, p)
end

local chi_square_test_value = function(p_observed, p)
  return 2 * likelihood_ratio(p_observed, p)
end

local chi_square_test = function(test_value, k, confidence)
  local cdf = chi_square[confidence][k]
  assert(cdf ~= nil, "unknown cdf distribution")
  return test_value > cdf
end

local mgof_windows = function(elements, classifier)
  local m = 1 -- tracks the current number of null hypothesis
  local p = {} -- array of window distributions
  local c = {} -- array that counts how many time window was used to explain other
  local anomaly
  local best_test_value
  for w_start = 1, #elements, w_size + 1 do
    anomaly = false
    c[m] = 0
    local size = math.min(w_size, #elements - w_start)
    local p_observed = distribution(elements, n_bins, classifier, w_start, size)
    if m == 1 then
      c[m] = c[m] + 1
    else
      best_test_value = 9999
      local best_window_index = 0
      for i = 1, m - 1 do
        local test_value = chi_square_test_value(p_observed, p[i])
        if test_value < best_test_value then
          best_test_value = test_value
          best_window_index = i
        end
      end
      if not chi_square_test(best_test_value, n_bins - 1, confidence) then
        c[best_window_index] = c[best_window_index] + 1
        anomaly = c[best_window_index] < c_th
      else
        anomaly = true
      end
    end
    p[m] = p_observed
    m = m + 1
  end
  return {(anomaly and 1 or 0), tostring(best_test_value)}
end

local mgof_last_window = function(elements, classifier)
  local p = distribution(elements, n_bins, classifier)
  local p_observed = distribution(elements, n_bins, classifier, #elements - w_size, w_size)
  local test_value = chi_square_test_value(p_observed, p)
  local anomaly = chi_square_test(test_value, n_bins - 1, confidence)
  return {(anomaly and 1 or 0), tostring(test_value)}
end

local elements = time_series_to_values(redis.call('ZRANGEBYSCORE', key, '-inf', '+inf'))
local classifier = create_bin_classifier(elements, n_bins)

return mgof_windows(elements, classifier)
