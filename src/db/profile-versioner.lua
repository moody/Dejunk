local _, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local ProfileVersioner = Addon.ProfileVersioner

-- Versions
ProfileVersioner.CURRENT_VERSION = 1
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

  profile.sell.byType.belowAverageItemLevel.value = Clamp(
    profile.sell.byType.belowAverageItemLevel.value,
    Consts.SELL_BELOW_AVERAGE_ILVL_MIN,
    Consts.SELL_BELOW_AVERAGE_ILVL_MAX
  )

  profile.destroy.autoSlider = Clamp(
    profile.destroy.autoSlider,
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
end
