-- DB: provides addon modules easy access to saved variables.

local AddonName, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DB = Addon.DB

-- Default database values
local defaults = {
  Global = {
    Minimap = { hide = false },
    ItemTooltip = true
  },
  Profile = {
    -- General options
    SilentMode = false,
    VerboseMode = true,
    AutoSell = false,
    SafeMode = true,
    AutoRepair = false,
    UseGuildRepair = true,
    SellBelowPrice = {
      Enabled = false,
      Value = Consts.SELL_BELOW_PRICE_MIN
    },

    -- Sell options
    SellPoor = true,
    SellCommon = false,
    SellUncommon = false,
    SellRare = false,
    SellEpic = false,

    SellUnsuitable = false,
    SellBelowAverageILVL = {
      Enabled = false,
      Value = Consts.SELL_BELOW_AVERAGE_ILVL_MIN
    },

    -- Ignore options
    IgnoreBattlePets = false,
    IgnoreBindsWhenEquipped = false,
    IgnoreConsumables = false,
    IgnoreCosmetic = false,
    IgnoreEquipmentSets = false,
    IgnoreGems = false,
    IgnoreGlyphs = false,
    IgnoreItemEnhancements = false,
    IgnoreQuestItems = false,
    IgnoreReadable = false,
    IgnoreReagents = false,
    IgnoreRecipes = false,
    IgnoreSoulbound = false,
    IgnoreTradeable = false,
    IgnoreTradeGoods = false,

    -- Destroy options
    AutoDestroy = false,
    DestroyBelowPrice = {
      Enabled = false,
      Value = Consts.DESTROY_BELOW_PRICE_MIN
    },
    DestroyPoor = false,
    DestroyCommon = false,
    DestroyUncommon = false,
    DestroyRare = false,
    DestroyEpic = false,
    DestroyPetsAlreadyCollected = false,
    DestroyToysAlreadyCollected = false,
    DestroyExcessSoulShards = {
      Enabled = false,
      Value = Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN
    },

    DestroyIgnoreBattlePets = false,
    DestroyIgnoreBindsWhenEquipped = false,
    DestroyIgnoreConsumables = false,
    DestroyIgnoreCosmetic = false,
    DestroyIgnoreEquipmentSets = false,
    DestroyIgnoreGems = false,
    DestroyIgnoreGlyphs = false,
    DestroyIgnoreItemEnhancements = false,
    DestroyIgnoreQuestItems = false,
    DestroyIgnoreReadable = false,
    DestroyIgnoreReagents = false,
    DestroyIgnoreRecipes = false,
    DestroyIgnoreSoulbound = false,
    DestroyIgnoreTradeable = false,
    DestroyIgnoreTradeGoods = false,

    -- Lists, table of itemIDs: { ["itemID"] = true }
    Inclusions = {},
    Exclusions = {},
    Destroyables = {},
    Undestroyables = {}
  }
}

-- ============================================================================
-- Database Functions
-- ============================================================================

local conversions = {
  -- DestroyPriceThreshold -> DestroyBelowPrice
  function(profile)
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
  end,

  -- Clamp min-max values
  function(profile)
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
  end,

  -- Remove `DestroyIgnoreExclusions` & `DestroyInclusions`
  function(profile)
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

-- Converts the old version of the DB into the new one.
local function reformat()
  -- Perform conversions on all profiles
  for _, profile in pairs(_G.DEJUNK_ADDON_SV.Profiles) do
    for _, conversion in ipairs(conversions) do
      conversion(profile)
    end
  end
end

-- Initializes the database.
function DB:Initialize()
  self.Initialize = nil
  local db = Addon.DethsDBLib(AddonName, defaults)
  setmetatable(self, { __index = db })
  self.Reformat = reformat
  reformat()
  Addon.EventManager:Fire("DB_PROFILE_CHANGED")
end
