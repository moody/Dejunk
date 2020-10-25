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
  test("clamps `sell.belowPrice`", function(expect)
    local profile = DatabaseUtils:Profile()
    -- min
    profile.sell.belowPrice.value = Consts.SELL_BELOW_PRICE_MIN - 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.belowPrice.value).toBe(Consts.SELL_BELOW_PRICE_MIN)
    -- current
    profile.sell.belowPrice.value = Consts.SELL_BELOW_PRICE_MIN + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.belowPrice.value).toBe(Consts.SELL_BELOW_PRICE_MIN + 1)
    -- max
    profile.sell.belowPrice.value = Consts.SELL_BELOW_PRICE_MAX + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.belowPrice.value).toBe(Consts.SELL_BELOW_PRICE_MAX)
  end)

  test("clamps `sell.byType.belowAverageItemLevel`", function(expect)
    local profile = DatabaseUtils:Profile()
    -- min
    profile.sell.byType.belowAverageItemLevel.value =
      Consts.SELL_BELOW_AVERAGE_ILVL_MIN - 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.byType.belowAverageItemLevel.value).toBe(
      Consts.SELL_BELOW_AVERAGE_ILVL_MIN
    )
    -- current
    profile.sell.byType.belowAverageItemLevel.value =
      Consts.SELL_BELOW_AVERAGE_ILVL_MIN + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.byType.belowAverageItemLevel.value).toBe(
      Consts.SELL_BELOW_AVERAGE_ILVL_MIN + 1
    )
    -- max
    profile.sell.byType.belowAverageItemLevel.value =
      Consts.SELL_BELOW_AVERAGE_ILVL_MAX + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.sell.byType.belowAverageItemLevel.value).toBe(
      Consts.SELL_BELOW_AVERAGE_ILVL_MAX
    )
  end)

  test("clamps `destroy.autoSlider`", function(expect)
    local profile = DatabaseUtils:Profile()
    -- min
    profile.destroy.autoSlider = Consts.DESTROY_AUTO_SLIDER_MIN - 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.autoSlider).toBe(Consts.DESTROY_AUTO_SLIDER_MIN)
    -- current
    profile.destroy.autoSlider = Consts.DESTROY_AUTO_SLIDER_MIN + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.autoSlider).toBe(Consts.DESTROY_AUTO_SLIDER_MIN + 1)
    -- max
    profile.destroy.autoSlider = Consts.DESTROY_AUTO_SLIDER_MAX + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.autoSlider).toBe(Consts.DESTROY_AUTO_SLIDER_MAX)
  end)

  test("clamps `destroy.belowPrice`", function(expect)
    local profile = DatabaseUtils:Profile()
    -- min
    profile.destroy.belowPrice.value = Consts.DESTROY_BELOW_PRICE_MIN - 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.belowPrice.value).toBe(
      Consts.DESTROY_BELOW_PRICE_MIN
    )
    -- current
    profile.destroy.belowPrice.value = Consts.DESTROY_BELOW_PRICE_MIN + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.belowPrice.value).toBe(
      Consts.DESTROY_BELOW_PRICE_MIN + 1
    )
    -- max
    profile.destroy.belowPrice.value = Consts.DESTROY_BELOW_PRICE_MAX + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.belowPrice.value).toBe(
      Consts.DESTROY_BELOW_PRICE_MAX
    )
  end)

  test("clamps `destroy.byType.excessSoulShards`", function(expect)
    local profile = DatabaseUtils:Profile()
    -- min
    profile.destroy.byType.excessSoulShards.value =
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN - 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.byType.excessSoulShards.value).toBe(
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN
    )
    -- current
    profile.destroy.byType.excessSoulShards.value =
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.byType.excessSoulShards.value).toBe(
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN + 1
    )
    -- max
    profile.destroy.byType.excessSoulShards.value =
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX + 1
    ProfileVersioner:_ClampValues(profile)
    expect(profile.destroy.byType.excessSoulShards.value).toBe(
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX
    )
  end)
end)

instance.describe("versions", function(test)
  test("has expected functions", function(expect)
    for i=2, ProfileVersioner.CURRENT_VERSION do
      expect(type(ProfileVersioner.versions[i])).toBe("function")
    end
  end)
end)
