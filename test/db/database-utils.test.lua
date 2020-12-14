local _, Addon = ...
if not Addon.West then return end
local DatabaseUtils = Addon.DatabaseUtils
local instance = Addon.West.subinstance("DatabaseUtils")

instance.describe("EnsureKey()", function(test)
  test("adds default values for keys that do not exist", function(expect)
    local t = {}
    DatabaseUtils:EnsureKey(t, "key", "value")
    expect(t.key).toBe("value")
  end)

  test("overwrites keys that have invalid types", function(expect)
    local t = { b = "2" }
    DatabaseUtils:EnsureKey(t, "b", 2)
    expect(t.b).toBe(2)
  end)

  test("ignores keys that have valid types", function(expect)
    local t = { a = false }
    DatabaseUtils:EnsureKey(t, "a", true)
    expect(t.a).toBe(false)
  end)

  test("ensures nested values exist", function(expect)
    local t = { a = { b = {} } }
    DatabaseUtils:EnsureKey(t, "a", { b = { c = 1 } })
    expect(t.a.b.c).toBe(1)
  end)
end)
