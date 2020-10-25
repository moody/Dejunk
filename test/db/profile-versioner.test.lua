local _, Addon = ...
if not Addon.West then return end
local DatabaseUtils = Addon.DatabaseUtils
local ProfileVersioner = Addon.ProfileVersioner
local instance = Addon.West.subinstance("ProfileVersioner")

instance.test("versions", function(expect)
  for i=2, ProfileVersioner.CURRENT_VERSION do
    expect(type(ProfileVersioner.versions[i])).toBe("function")
  end
end)

instance.describe("_Update()", function(test)
  test("converts default to current version", function(expect)
    local profile = { version = ProfileVersioner.DEFAULT_VERSION }
    ProfileVersioner:_Update(profile)
    expect(profile.version).toBe(ProfileVersioner.CURRENT_VERSION)
  end)

  test("does nothing if version >= current", function(expect)
    local expected = DatabaseUtils:Profile()
    expected.version = ProfileVersioner.CURRENT_VERSION

    local profile = DatabaseUtils:Profile()
    ProfileVersioner:_Update(profile)
    expect(profile).toEqual(expected)

    profile.version = profile.version + 1
    local expectedVersion = profile.version
    ProfileVersioner:_Update(profile)
    expect(profile.version).toEqual(expectedVersion)
  end)
end)
