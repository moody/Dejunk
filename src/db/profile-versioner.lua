local _, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DatabaseUtils = Addon.DatabaseUtils
local ProfileVersioner = Addon.ProfileVersioner

-- Versions
ProfileVersioner.CURRENT_VERSION = 3
ProfileVersioner.DEFAULT_VERSION = -1

ProfileVersioner.versions = {}

-- ============================================================================
-- Functions
-- ============================================================================

function ProfileVersioner:Run(profile)
  self:_Update(profile)
  self:_ClampValues(profile)
end

function ProfileVersioner:_AddVersion(version, func)
  assert(type(version) == "number")
  assert(type(func) == "function")
  assert(version > 1 and version <= ProfileVersioner.CURRENT_VERSION)
  assert(self.versions[version] == nil)
  self.versions[version] = function(profile)
    func(profile)
    profile.version = version
  end
end

function ProfileVersioner:_Update(profile)
  if profile.version == self.DEFAULT_VERSION then
    profile.version = self.CURRENT_VERSION
  end

  while profile.version < self.CURRENT_VERSION do
    self.versions[profile.version+1](profile)
  end
end

function ProfileVersioner:_ClampValues(profile)
  profile.sell.belowPrice.value = Clamp(
    profile.sell.belowPrice.value,
    Consts.SELL_BELOW_PRICE_MIN,
    Consts.SELL_BELOW_PRICE_MAX
  )

  profile.sell.byType.itemLevelRange.min = Clamp(
    profile.sell.byType.itemLevelRange.min,
    Consts.ITEM_LEVEL_RANGE_MIN,
    profile.sell.byType.itemLevelRange.max
  )

  profile.sell.byType.itemLevelRange.max = Clamp(
    profile.sell.byType.itemLevelRange.max,
    profile.sell.byType.itemLevelRange.min,
    Consts.ITEM_LEVEL_RANGE_MAX
  )

  profile.destroy.autoOpen.value = Clamp(
    profile.destroy.autoOpen.value,
    Consts.DESTROY_AUTO_SLIDER_MIN,
    Consts.DESTROY_AUTO_SLIDER_MAX
  )

  profile.destroy.autoStart.value = Clamp(
    profile.destroy.autoStart.value,
    Consts.DESTROY_AUTO_SLIDER_MIN,
    Consts.DESTROY_AUTO_SLIDER_MAX
  )

  profile.destroy.belowPrice.value = Clamp(
    profile.destroy.belowPrice.value,
    Consts.DESTROY_BELOW_PRICE_MIN,
    Consts.DESTROY_BELOW_PRICE_MAX
  )

  profile.destroy.byType.excessSoulShards.value = Clamp(
    profile.destroy.byType.excessSoulShards.value,
    Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN,
    Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX
  )

  profile.destroy.byType.itemLevelRange.min = Clamp(
    profile.destroy.byType.itemLevelRange.min,
    Consts.ITEM_LEVEL_RANGE_MIN,
    profile.destroy.byType.itemLevelRange.max
  )

  profile.destroy.byType.itemLevelRange.max = Clamp(
    profile.destroy.byType.itemLevelRange.max,
    profile.destroy.byType.itemLevelRange.min,
    Consts.ITEM_LEVEL_RANGE_MAX
  )
end

-- ============================================================================
-- Version 2
-- ============================================================================

ProfileVersioner:_AddVersion(2, function(profile)
  -- Remove old settings.
  profile.destroy.auto = nil
  profile.destroy.autoSlider = nil

  -- Ensure `destroy.autoOpen` & `destroy.autoStart`.
  for _, k in pairs({ "autoOpen", "autoStart" }) do
    DatabaseUtils:EnsureKey(profile.destroy, k, {
      enabled = false,
      value = Consts.DESTROY_AUTO_SLIDER_MIN,
    })
  end
end)

-- ============================================================================
-- Version 3
-- ============================================================================

ProfileVersioner:_AddVersion(3, function(profile)
  -- Remove old settings.
  profile.sell.byType.belowAverageItemLevel = nil

  -- Ensure `sell.byType.itemLevelRange`.
  DatabaseUtils:EnsureKey(profile.sell.byType, 'itemLevelRange', {
    enabled = false,
    min = Consts.ITEM_LEVEL_RANGE_MIN,
    max = Consts.ITEM_LEVEL_RANGE_MIN,
  })

  -- Ensure `destroy.byType.itemLevelRange`.
  DatabaseUtils:EnsureKey(profile.destroy.byType, 'itemLevelRange', {
    enabled = false,
    min = Consts.ITEM_LEVEL_RANGE_MIN,
    max = Consts.ITEM_LEVEL_RANGE_MIN,
  })
end)
