package.path = "scripts/?.lua;spec/?.lua;" .. package.path
local utils = require "utils"

describe("time_series_to_values", function()
  it("should handle integer timestamps", function()
    assert.same({42}, utils.time_series_to_values({"1400000:42"}))
  end)

  it("should handle floating point timestamps", function()
    assert.same({42}, utils.time_series_to_values({"1400000.1234:42"}))
  end)

  it("should handle floating point values", function()
    assert.same({42.42}, utils.time_series_to_values({"1400000.1234:42.42"}))
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
    assert.same({0, 0, 0, 0}, utils.distribution({}, n_bins, cf))
    assert.same({1, 0, 0, 0}, utils.distribution({1}, n_bins, cf))
    assert.same({0, 0, 0, 1}, utils.distribution({90}, n_bins, cf))
    assert.same({0.5, 0, 0, 0.5}, utils.distribution({1, 90}, n_bins, cf))
    assert.same({0.25, 0.5, 0, 0.25}, utils.distribution({1, 40, 45, 90}, n_bins, cf))
  end)

  it("should use given offset and size", function()
    local n_bins = 4
    local cf = utils.create_bin_classifier({}, n_bins, 0, 100)
    assert.same({0.25, 0.5, 0, 0.25}, utils.distribution({
        1, 2, 3, 4, 5, 6, 7, 8, 9, -- ignored
        1, 40, 45, 90,
        1, 2, 3, 4, 5, 6, 7, 8, 9 -- ignored
      }, n_bins, cf, 10, 4))
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
