local _, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DB = Addon.DB

local conversions = {}

-- Updates and constrains database values.
function Addon:ReformatDB()
  assert(DB.Global and DB.Profiles, "SavedVariables not loaded")

  for _, conversion in ipairs(conversions) do
    -- Convert global data
    if type(conversion.global) == "function" then
      conversion.global(DB.Global)
    end

    -- Convert profile data
    if type(conversion.profile) == "function" then
      for _, profile in pairs(DB.Profiles) do
        conversion.profile(profile)
      end
    end
  end
end

-- ============================================================================
-- DestroyPriceThreshold -> DestroyBelowPrice
-- ============================================================================

conversions.profile[#conversions.profile+1] = {
  profile = function(profile)
    if type(profile.DestroyUsePriceThreshold) == "boolean" then
      profile.DestroyBelowPrice.Enabled = profile.DestroyUsePriceThreshold
    end

    if type(profile.DestroyPriceThreshold) == "table" then
      profile.DestroyBelowPrice.Value =
        ((profile.DestroyPriceThreshold.Gold or 0) * 100 * 100) +
        ((profile.DestroyPriceThreshold.Silver or 0) * 100) +
        (profile.DestroyPriceThreshold.Copper or 0)
    end

    profile.DestroyUsePriceThreshold = nil
    profile.DestroyPriceThreshold = nil
  end
}

-- ============================================================================
-- Remove `DestroyIgnoreExclusions` & `DestroyInclusions`
-- ============================================================================

conversions.profile[#conversions.profile+1] = {
  profile = function(profile)
    if profile.DestroyIgnoreExclusions then
      for k in pairs(profile.Exclusions) do
        profile.Destroyables[k] = nil
        profile.Undestroyables[k] = true
      end
    end

    profile.DestroyIgnoreExclusions = nil
    profile.DestroyInclusions = nil
  end
}

-- ============================================================================
-- 8.3.4 -> 8.3.5
-- ============================================================================

conversions[#conversions+1] = {
  global = function(global)
    -- Minimap -> minimapIcon
    if type(global.Minimap) ~= "nil" then
      global.minimapIcon = global.Minimap
      global.Minimap = nil
    end

    -- ItemTooltip -> showItemTooltip
    if type(global.ItemTooltip) ~= "nil" then
      global.showItemTooltip = global.ItemTooltip
      global.ItemTooltip = nil
    end

    -- MerchantButton -> showMerchantButton
    if type(global.MerchantButton) ~= "nil" then
      global.showMerchantButton = global.MerchantButton
      global.MerchantButton = nil
    end
  end,

  profile = function(profile)
    do -- General
      for oldKey, newKey in pairs({
        SilentMode = "silentMode",
        VerboseMode = "verboseMode",
        AutoRepair = "autoRepair",
        UseGuildRepair = "useGuildRepair",
      }) do
        if type(profile[oldKey]) ~= "nil" then
          profile.general[newKey] = profile[oldKey]
          profile[oldKey] = nil
        end
      end
    end
  end,
}

-- ============================================================================
-- Clamp min-max values
-- ============================================================================

conversions.profile[#conversions.profile+1] = {
  profile = function(profile)
    profile.SellBelowPrice.Value = Clamp(
      profile.SellBelowPrice.Value,
      Consts.SELL_BELOW_PRICE_MIN,
      Consts.SELL_BELOW_PRICE_MAX
    )

    profile.SellBelowAverageILVL.Value = Clamp(
      profile.SellBelowAverageILVL.Value,
      Consts.SELL_BELOW_AVERAGE_ILVL_MIN,
      Consts.SELL_BELOW_AVERAGE_ILVL_MAX
    )

    profile.DestroyBelowPrice.Value = Clamp(
      profile.DestroyBelowPrice.Value,
      Consts.DESTROY_BELOW_PRICE_MIN,
      Consts.DESTROY_BELOW_PRICE_MAX
    )

    profile.DestroyExcessSoulShards.Value = Clamp(
      profile.DestroyExcessSoulShards.Value,
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN,
      Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX
    )

    profile.DestroySaveSpace.Value = Clamp(
      profile.DestroySaveSpace.Value,
      Consts.DESTROY_SAVE_SPACE_MIN,
      Consts.DESTROY_SAVE_SPACE_MAX
    )
  end
}
