local _, Addon = ...
if not Addon.West then return end
local Consts = Addon.Consts
local DatabaseUtils = Addon.DatabaseUtils
local ProfileVersioner = Addon.ProfileVersioner
local instance = Addon.West.subinstance("ProfileVersioner")

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

instance.describe("_ClampValues()", function(test)
  local function clampTest(options)
    test(options.message, function(expect)
      local profile = DatabaseUtils:Profile()

      -- min
      options.set(profile, options.min - 1)
      ProfileVersioner:_ClampValues(profile)
      expect(options.get(profile)).toBe(options.min)

      -- midrange
      local midrange = (options.max + options.min) / 2
      options.set(profile, midrange)
      ProfileVersioner:_ClampValues(profile)
      expect(options.get(profile)).toBe(midrange)

      -- max
      options.set(profile, options.max + 1)
      ProfileVersioner:_ClampValues(profile)
      expect(options.get(profile)).toBe(options.max)
    end)
  end

  clampTest({
    message = "sell.belowPrice",
    get = function(p) return p.sell.belowPrice.value end,
    set = function(p, v) p.sell.belowPrice.value = v end,
    min = Consts.SELL_BELOW_PRICE_MIN,
    max = Consts.SELL_BELOW_PRICE_MAX,
  })

  clampTest({
    message = "sell.byType.belowAverageItemLevel",
    get = function(p) return p.sell.byType.belowAverageItemLevel.value end,
    set = function(p, v) p.sell.byType.belowAverageItemLevel.value = v end,
    min = Consts.SELL_BELOW_AVERAGE_ILVL_MIN,
    max = Consts.SELL_BELOW_AVERAGE_ILVL_MAX,
  })

  clampTest({
    message = "destroy.autoOpen.value",
    get = function(p) return p.destroy.autoOpen.value end,
    set = function(p, v) p.destroy.autoOpen.value = v end,
    min = Consts.DESTROY_AUTO_SLIDER_MIN,
    max = Consts.DESTROY_AUTO_SLIDER_MAX,
  })

  clampTest({
    message = "destroy.autoStart.value",
    get = function(p) return p.destroy.autoStart.value end,
    set = function(p, v) p.destroy.autoStart.value = v end,
    min = Consts.DESTROY_AUTO_SLIDER_MIN,
    max = Consts.DESTROY_AUTO_SLIDER_MAX,
  })

  clampTest({
    message = "destroy.belowPrice",
    get = function(p) return p.destroy.belowPrice.value end,
    set = function(p, v) p.destroy.belowPrice.value = v end,
    min = Consts.DESTROY_BELOW_PRICE_MIN,
    max = Consts.DESTROY_BELOW_PRICE_MAX,
  })

  clampTest({
    message = "destroy.byType.excessSoulShards",
    get = function(p) return p.destroy.byType.excessSoulShards.value end,
    set = function(p, v) p.destroy.byType.excessSoulShards.value = v end,
    min = Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN,
    max = Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX,
  })
end)

instance.describe("versions", function(test)
  test("has expected functions", function(expect)
    for i=2, ProfileVersioner.CURRENT_VERSION do
      expect(type(ProfileVersioner.versions[i])).toBe("function")
    end
  end)

  test("Version 2", function(expect)
    local profile = {
      version = 1,
      destroy = { auto = false, autoSlider = 0 },
    }
    ProfileVersioner.versions[2](profile)
    expect(profile.version).toBe(2)
    expect(profile.destroy.auto).toBe(nil)
    expect(profile.destroy.autoSlider).toBe(nil)
    expect(profile.destroy.autoOpen).toEqual({
      enabled = false,
      value = Consts.DESTROY_AUTO_SLIDER_MIN,
    })
    expect(profile.destroy.autoStart).toEqual({
      enabled = false,
      value = Consts.DESTROY_AUTO_SLIDER_MIN,
    })
  end)
end)
