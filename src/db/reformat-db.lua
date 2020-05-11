local _, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DB = Addon.DB

local conversions = {
  global = {},
  profile = {}
}

-- Updates values in the DB to match the latest specification.
function Addon:ReformatDB()
  assert(DB.Global and DB.Profiles, "SavedVariables not loaded")

  -- Convert global data
  for _, conversion in ipairs(conversions.global) do
    conversion(DB.Global)
  end

  -- Convert profile data
  for _, profile in pairs(DB.Profiles) do
    for _, conversion in ipairs(conversions.profile) do
      conversion(profile)
    end
  end
end

-- ============================================================================
-- Global Conversions
-- ============================================================================

-- 8.3.4 -> 8.3.5
conversions.global[#conversions.global+1] = function(global)
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
end

-- ============================================================================
-- Profile Conversions
-- ============================================================================

-- DestroyPriceThreshold -> DestroyBelowPrice
conversions.profile[#conversions.profile+1] = function(profile)
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


-- Remove `DestroyIgnoreExclusions` & `DestroyInclusions`
conversions.profile[#conversions.profile+1] = function(profile)
  if profile.DestroyIgnoreExclusions then
    for k in pairs(profile.Exclusions) do
      profile.Destroyables[k] = nil
      profile.Undestroyables[k] = true
    end
  end

  profile.DestroyIgnoreExclusions = nil
  profile.DestroyInclusions = nil
end


-- -- 8.3.4 -> 8.3.5
-- conversions.profile[#conversions.profile+1] = function(profile)
-- end


-- Clamp min-max values
conversions.profile[#conversions.profile+1] = function(profile)
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
