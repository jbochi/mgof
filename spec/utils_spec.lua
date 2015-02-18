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
