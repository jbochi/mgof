package.path = "scripts/?.lua;spec/?.lua;" .. package.path

function run_in_context(filename, context)
  local f = assert(loadfile(filename))
  setmetatable(context, {__index=_G})
  local scoped_f = load(string.dump(f), nil, nil, context)
  return scoped_f()
end

describe("tukey", function()
  it("should return false if there are not enough elements", function()
    local context = {
      KEYS={"TESTKEY"},
      ARGV={1},
      redis={
        call=function(command, key, min, max)
          assert(command == 'ZRANGEBYSCORE')
          assert(key == "TESTKEY")
          assert(min == "-inf")
          assert(max == '+inf')
          return {}
        end
    }}
    local range = run_in_context("scripts/tukey.lua", context)
    assert.falsy(range)
  end)

  it("should return range", function()
    local context = {
      KEYS={"TESTKEY"},
      ARGV={1},
      redis={
        call=function(command, key, min, max)
          assert(command == 'ZRANGEBYSCORE')
          assert(key == "TESTKEY")
          assert(min == "-inf")
          assert(max == '+inf')
          return {2, 2, 4, 4}
        end
    }}
    local range = run_in_context("scripts/tukey.lua", context)
    assert.equals(0, tonumber(range[1]))
    assert.equals(6, tonumber(range[2]))
  end)
end)
