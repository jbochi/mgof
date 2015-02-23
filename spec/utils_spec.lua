package.path = "scripts/?.lua;spec/?.lua;" .. package.path
_G.redis = require "fake_redis"
local utils = require "utils"

local cleanup_redis = function()
  redis.call("del", "key")
end

before_each(cleanup_redis)

after_each(cleanup_redis)

describe("add_point", function()
  it("should add metric point to redis ang get value back", function()
    utils.add_value("key", 1400000, 42)
    assert.same({{1400000, 42}},  utils.time_series("key"))
    assert.same({42},  utils.time_series_values("key"))
  end)

  it("should handle floating point", function()
    utils.add_value("key", 1400000.42, 42.42)
    assert.same({{1400000.42, 42.42}},  utils.time_series("key"))
    assert.same({42.42},  utils.time_series_values("key"))
  end)
end)

describe("bin classifier", function()
  it("should infer min and max from timeseries", function()
    local cf = utils.create_bin_classifier({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 10)
    assert.same(1, cf(1))
    assert.same(2, cf(1.1))
    assert.same(5, cf(5))
    assert.same(10, cf(10))
  end)

  it("should use the correct amount of bins", function()
    local cf = utils.create_bin_classifier({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 2)
    assert.same(1, cf(1))
    assert.same(1, cf(5))
    assert.same(2, cf(10))
  end)

  it("should handle value values outside min-max range", function()
    local cf = utils.create_bin_classifier({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 10)
    assert.same(1, cf(-15))
    assert.same(10, cf(15))
  end)

  it("should use provided min/max values", function()
    local cf = utils.create_bin_classifier({4, 5, 6}, 10, 0, 10)
    assert.same(1, cf(0))
    assert.same(1, cf(1))
    assert.same(5, cf(5))
    assert.same(9, cf(9))
    assert.same(10, cf(10))
  end)
end)

describe("distribution", function()
  it("should return percentile of values in each bin", function()
    local n_bins = 4
    local cf = utils.create_bin_classifier({}, n_bins, 0, 100)
    assert.same({0, 0, 0, 0}, utils.distribution({}, cf))
    assert.same({1, 0, 0, 0}, utils.distribution({1}, cf))
    assert.same({0, 0, 0, 1}, utils.distribution({90}, cf))
    assert.same({0.5, 0, 0, 0.5}, utils.distribution({1, 90}, cf))
    assert.same({0.25, 0.5, 0, 0.25}, utils.distribution({1, 40, 45, 90}, cf))
  end)

  it("should use given offset and size", function()
    local n_bins = 4
    local cf = utils.create_bin_classifier({}, n_bins, 0, 100)
    assert.same({0.25, 0.5, 0, 0.25}, utils.distribution({
        1, 2, 3, 4, 5, 6, 7, 8, 9, -- ignored
        1, 40, 45, 90,
        1, 2, 3, 4, 5, 6, 7, 8, 9 -- ignored
      }, cf, 10, 4))
  end)
end)

describe("relative_entropy", function()
  it("should be 0 for equal distributions", function()
    assert.equals(0, utils.relative_entropy({0.5, 0.5}, {0.5, 0.5}))
    assert.equals(0, utils.relative_entropy({0.4, 0.2, 0, 0.4}, {0.4, 0.2, 0, 0.4}))
  end)

  it("should be +inf for opposite distributions", function()
    assert.equals(math.huge, utils.relative_entropy({1, 0, 0, 0}, {0, 0, 0, 1}))
  end)

  it("should follow the formula", function()
    assert.equals(1 * math.log(1/0.4),
      utils.relative_entropy({0, 0, 1, 0}, {0.1, 0.4, 0.4, 0.1}))

    assert.equals(0.2 * math.log(0.2/0.1) + 0.8 * math.log(0.8/0.4),
      utils.relative_entropy({0.2, 0, 0.8, 0}, {0.1, 0.4, 0.4, 0.1}))
  end)
end)

describe("chi_square_test_value", function()
  it("should return correct value", function()
    assert.equals(200 * math.log(1/0.4),
      utils.chi_square_test_value({0, 0, 1, 0}, {0.1, 0.4, 0.4, 0.1}, 100))
  end)
end)


describe("chi_square_test", function()
  it("should follow correct thresholds", function()
    assert.truthy(utils.chi_square_test(65.7123, 1, 95))
    assert.truthy(utils.chi_square_test(16.2, 1, 95))
    assert.truthy(utils.chi_square_test(16.2, 1, 99))
    assert.falsy(utils.chi_square_test(4.8696, 3, 95))
    assert.falsy(utils.chi_square_test(1.1683, 1, 95))
  end)
end)


describe("mgof_last_window", function()
  it("should be false for steady distribution", function()
    local cf = utils.create_bin_classifier({}, 10, 0, 10)
    local elements = {}
    local options = {w_size=10, confidence=95}
    for i = 1,100 do
      elements[#elements + 1] = 4
    end
    assert.falsy(utils.mgof_last_window(elements, cf, options))
  end)

  it("should be true for anomal window", function()
    local cf = utils.create_bin_classifier({}, 10, 0, 10)
    local elements = {}
    local options = {w_size=10, confidence=95}
    for i = 1,100 do
      elements[#elements + 1] = 4 + i/100
    end
    for i = 1, 10 do
      elements[#elements + 1] = 9
    end
    assert.truthy(utils.mgof_last_window(elements, cf, options))
  end)
end)


describe("mgof", function()
  it("should be false for steady distribution", function()
    local cf = utils.create_bin_classifier({}, 10, 0, 10)
    local elements = {}
    local options = {w_size=10, confidence=95, c_th=1}
    local distributions = {
      {percentiles={0, 0, 0.5, 0.5, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.6, 0.4, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.55, 0.45, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.57, 0.43, 0, 0, 0, 0, 0, 0}, size=60}
    }
    assert.falsy(utils.mgof(distributions, cf, options))
  end)

  it("should be true if last window is anomalous", function()
    local cf = utils.create_bin_classifier({}, 10, 0, 10)
    local elements = {}
    local options = {w_size=10, confidence=95, c_th=1}
    local distributions = {
      {percentiles={0, 0, 0.5, 0.5, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.6, 0.4, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.55, 0.45, 0, 0, 0, 0, 0, 0}, size=60},
      {percentiles={0, 0, 0.97, 0.03, 0, 0, 0, 0, 0, 0}, size=60}
    }
    assert.truthy(utils.mgof(distributions, cf, options))
  end)
end)

describe("last window range", function()
  it("should be the last fully completed window", function()
    assert.same({100200, 100250}, utils.last_window_range(100280, 50))
    assert.same({100200, 100250}, utils.last_window_range(100290, 50))
    assert.same({100250, 100300}, utils.last_window_range(100300, 50))
    assert.same({100250, 100300}, utils.last_window_range(100310, 50))
  end)
end)

describe("distributions", function()
  it("should return an empty list if there is no datapoint", function()
    assert.same({}, utils.distributions("key"))
  end)

  it("should compute distribution from timeseries", function()
    local w_size = 20
    local cf = utils.create_bin_classifier({}, 10, 0, 100)
    for i = 6, 110 do
      utils.add_value("key", 100000 + i, i)
    end

    local distributions = utils.distributions("key", cf, w_size)
    assert.same(5, #distributions)

    assert.same(100000, distributions[1].start)
    assert.same(100020, distributions[1].stop)
    assert.same(15, distributions[1].size)

    assert.same(100080, distributions[5].start)
    assert.same(100100, distributions[5].stop)
    assert.same(20, distributions[5].size)

    assert.same(10, #distributions[1].percentiles)
    assert.same({5/15, 10/15, 0, 0, 0, 0, 0, 0, 0, 0}, distributions[1].percentiles)
    assert.same({0, 0, 0.5, 0.5, 0, 0, 0, 0, 0, 0}, distributions[2].percentiles)
    assert.same({0, 0, 0, 0, 0.5, 0.5, 0, 0, 0, 0}, distributions[3].percentiles)
    assert.same({0, 0, 0, 0, 0, 0, 0.5, 0.5, 0, 0}, distributions[4].percentiles)
    assert.same({0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.5}, distributions[5].percentiles)
  end)
end)
