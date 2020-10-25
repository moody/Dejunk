local _, Addon = ...
if not Addon.West then return end
local DatabaseUtils = Addon.DatabaseUtils
local GlobalVersioner = Addon.GlobalVersioner
local instance = Addon.West.subinstance("GlobalVersioner")

instance.test("versions", function(expect)
  for i=2, GlobalVersioner.CURRENT_VERSION do
    expect(type(GlobalVersioner.versions[i])).toBe("function")
  end
end)

instance.describe("Run()", function(test)
  test("converts default to current version", function(expect)
    local global = { version = GlobalVersioner.DEFAULT_VERSION }
    GlobalVersioner:Run(global)
    expect(global.version).toBe(GlobalVersioner.CURRENT_VERSION)
  end)

  test("does nothing if version >= current", function(expect)
    local expected = DatabaseUtils:Global()
    expected.version = GlobalVersioner.CURRENT_VERSION

    local global = DatabaseUtils:Global()
    GlobalVersioner:Run(global)
    expect(global).toEqual(expected)

    global.version = global.version + 1
    local expectedVersion = global.version
    GlobalVersioner:Run(global)
    expect(global.version).toEqual(expectedVersion)
  end)
end)
