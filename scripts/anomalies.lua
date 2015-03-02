local utils = require("utils")
local key = KEYS[1]


local distributions = utils.cached_distributions(key)
return utils.anomalous_windows(distributions)
