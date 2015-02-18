local utils = require("utils")
local options = {}

local key = KEYS[1]
local min_value = tonumber(ARGV[1])         -- min timeseries value
local max_value = tonumber(ARGV[2])         -- max timeseries value
options.n_bins = tonumber(ARGV[3]) or 10      -- number of bins: between 1 and 10
options.w_size = tonumber(ARGV[4]) or 60      -- window size
options.confidence = tonumber(ARGV[5]) or 99  -- test confidence (95 or 99)
options.c_th = tonumber(ARGV[6]) or 1         -- c_th is a threshold
                                            --   to determine if a hypothesis has
                                            --   occurred frequently enough
utils.debug_script = string.lower(ARGV[7]) == "true"  -- to debug or not

local elements = utils.time_series_to_values(redis.call('ZRANGEBYSCORE', key, '-inf', '+inf'))
local classifier = utils.create_bin_classifier(elements, options.n_bins, min_value, max_value)

return utils.mgof_windows(elements, classifier, options)
