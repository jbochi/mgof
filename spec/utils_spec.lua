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
    local cf = utils.create_bin_classifier({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 10)
    assert.same(1, cf(1))
    assert.same(5, cf(5))
    assert.same(10, cf(10))
  end)

  it("should use the correct amount of bins", function()
    local cf = utils.create_bin_classifier({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 2)
    assert.same(1, cf(1))
    assert.same(1, cf(5))
    assert.same(2, cf(10))
  end)

  it("should handle value values outside min-max range", function()
    local cf = utils.create_bin_classifier({1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, 10)
    assert.same(1, cf(-15))
    assert.same(10, cf(15))
  end)
end)
