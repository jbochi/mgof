local utils = {}

local chi_square = {[99]={6.63, 9.21, 11.34, 13.28, 15.09, 16.81, 18.48, 20.09, 21.67},
                    [95]={3.84, 5.99,  7.81,  9.49, 11.07, 12.59, 14.07, 15.51, 16.92}}


local serialize_value = function(timestamp, value)
  -- we add the timestamp prefix becuase sorted sets elements
  -- must be unique
  return timestamp .. ":" .. value
end

local parse_value = function(str)
  -- returns a pair of value, timestamp for a given record
  local colon = string.find(str, ":")
  local timestamp = tonumber(string.sub(str, 1, colon - 1))
  local value = tonumber(string.sub(str, colon + 1))
  return {timestamp, value}
end

utils.add_value = function(key, timestamp, value)
  return redis.call('zadd', key, timestamp, serialize_value(timestamp, value))
end

utils.time_series = function(key, start, stop)
  start = start or "-inf"
  stop = stop or "+inf"
  local elements = redis.call('zrangebyscore', key, start, stop)
  for i = 1, #elements do
    elements[i] = parse_value(elements[i])
  end
  return elements
end

utils.time_series_values = function(key)
  local elements = utils.time_series(key)
  for i = 1, #elements do
    elements[i] = elements[i][2]
  end
  return elements
end

local classifier_mt = {
  __call = function(self, value)
    if type(value) == "table" then
      value = value[2] -- value from timeseries table
    end
    return math.max(1, math.min(self.n_bins,
      math.ceil((value - self.min) / self.step_size)))
  end
}

utils.create_bin_classifier = function(time_series, n_bins, min, max)
  if min == nil or max == nil then
    for i = 1, #time_series do
      if min == nil or time_series[i] < min then
        min = time_series[i]
      end
      if max == nil or time_series[i] > max then
        max = time_series[i]
      end
    end
  end
  local classifier = {
    min=min,
    n_bins=n_bins,
    step_size=(max - min) / n_bins
  }
  setmetatable(classifier, classifier_mt)
  return classifier
end

utils.distribution = function(time_series, classifier, offset, size)
  offset = offset or 1
  size = size or (#time_series - offset + 1)
  local p = {}
  for i = offset, offset + size - 1 do
    local bin = classifier(time_series[i])
    p[bin] = (p[bin] or 0) + 1
  end
  for i = 1, classifier.n_bins do
    if p[i] == nil then
      p[i] = 0
    else
      p[i] = p[i] / size
    end
  end
  return p
end

utils.relative_entropy = function(p, q)
  -- http://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence
  local total = 0
  for i = 1, #p do
    if p[i] > 0 then
      total = total + p[i] * math.log(p[i] / q[i])
    end
  end
  return total
end

utils.chi_square_test_value = function(p_observed, p, n)
  return 2 * n * utils.relative_entropy(p_observed, p)
end

utils.chi_square_test = function(test_value, k, confidence)
  local cdf = chi_square[confidence][k]
  assert(cdf ~= nil, "unknown cdf distribution")
  return test_value > cdf
end

-- mgof of last window against all other datapoints distribution
utils.mgof_last_window = function(elements, classifier, options)
  local p = utils.distribution(elements, classifier, 1, #elements - options.w_size)
  local p_observed = utils.distribution(elements, classifier, #elements - options.w_size, options.w_size)
  local test_value = utils.chi_square_test_value(p_observed, p, options.w_size)
  local anomaly = utils.chi_square_test(test_value, classifier.n_bins - 1, options.confidence)
  return anomaly
end

-- mgof algorithm adapted from http://www.hpl.hp.com/techreports/2011/HPL-2011-8.pdf
utils.mgof = function(distributions, classifier, options)
  local anomaly
  local best_test_value

  for m, distribution in ipairs(distributions) do
    if distribution.anomaly ~= nil then
      anomaly = distribution.anomaly
    else
      anomaly = false
      local size = distribution.size
      local p_observed = distribution.percentiles
      if m == 1 then
        distribution:inc_occurrences()
      else
        best_test_value = math.huge
        local best_window_index = 0
        for i = 1, m - 1 do
          local p = distributions[i].percentiles
          local test_value = utils.chi_square_test_value(p_observed, p, size)
          if test_value < best_test_value then
            best_test_value = test_value
            best_window_index = i
          end
        end
        local k = classifier.n_bins - 1
        if not utils.chi_square_test(best_test_value, k, options.confidence) then
          local best_distribution = distributions[best_window_index]
          best_distribution:inc_occurrences()
          anomaly = best_distribution.occurrences < options.c_th
        else
          anomaly = true
        end
      end
      distribution:set_anomaly(anomaly)
    end
  end

  return anomaly
end

utils.last_window_range = function(now, w_size)
  local stop = math.floor(now / w_size) * w_size
  local start = stop - w_size
  return {start, stop}
end

local distribution_mt = {
  __index = {
    inc_occurrences = function(self)
      self.occurrences = self.occurrences + 1
    end,
    set_anomaly = function(self, anomaly)
      self.anomaly = anomaly
    end
  }
}

utils.new_distribution = function(percentiles, size, start, stop)
  local d = {
    start=start,
    stop=stop,
    size=size,
    percentiles=percentiles,
    anomaly=nil,
    occurrences=0
  }
  setmetatable(d, distribution_mt)
  return d
end

utils.distributions = function(key, classifier, w_size)
  local elements = utils.time_series(key, "-inf", "+inf")
  if #elements == 0 then
    return {}
  end

  local first_ts = elements[1][1]
  local current_window_stop_ts = utils.last_window_range(first_ts, w_size)[2]
  if current_window_stop_ts <= first_ts then
    current_window_stop_ts = current_window_stop_ts + w_size
  end
  local distributions = {}

  local current_window_start_index = 1

  for ix, element in ipairs(elements) do
    local ts = element[1]
    local value = element[2]

    if ts > current_window_stop_ts then
      -- last window is now complete, since there is a datapoint after it
      local w_start = current_window_start_index
      local size = ix - current_window_start_index
      local start = current_window_stop_ts - w_size
      local stop = current_window_stop_ts
      distributions[#distributions + 1] = utils.new_distribution(
        utils.distribution(elements, classifier, w_start, size),
        size,
        current_window_stop_ts - w_size,
        current_window_stop_ts
      )
      current_window_start_index = ix
      current_window_stop_ts = current_window_stop_ts + w_size
    end
  end

  return distributions
end

return utils
