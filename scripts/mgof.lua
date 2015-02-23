local utils = require("utils")
local options = {}

local key = KEYS[1]
local min_value = tonumber(ARGV[1])         -- min timeseries value
local max_value = tonumber(ARGV[2])         -- max timeseries value
local n_bins = tonumber(ARGV[3]) or 10      -- number of bins: between 1 and 10
options.w_size = tonumber(ARGV[4]) or 60      -- window size
options.confidence = tonumber(ARGV[5]) or 99  -- test confidence (95 or 99)
options.c_th = tonumber(ARGV[6]) or 1         -- c_th is a threshold
                                            --   to determine if a hypothesis has
                                            --   occurred frequently enough


local elements
if min_value == nil or max_value == nil then
  elements = utils.time_series_values(key)
end

local classifier = utils.create_bin_classifier(elements, n_bins, min_value, max_value)
local distributions = utils.distributions(key, classifier, options.w_size)
local anomaly = utils.mgof(distributions, classifier, options)

return anomaly and 1 or 0 -- convert to integer for redis reply
