-- DB: provides addon modules easy access to saved variables.

local AddonName, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local E = Addon.Events
local EventManager = Addon.EventManager

-- Default database values
local defaults = {
  Global = {
    Minimap = { hide = false },
    ItemTooltip = true,
    MerchantButton = true
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
    IgnoreMiscellaneous = false,
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
    DestroySaveSpace = {
      Enabled = false,
      Value = Consts.DESTROY_SAVE_SPACE_MIN
    },

    DestroyIgnoreBattlePets = false,
    DestroyIgnoreBindsWhenEquipped = false,
    DestroyIgnoreConsumables = false,
    DestroyIgnoreCosmetic = false,
    DestroyIgnoreEquipmentSets = false,
    DestroyIgnoreGems = false,
    DestroyIgnoreGlyphs = false,
    DestroyIgnoreItemEnhancements = false,
    DestroyIgnoreMiscellaneous = false,
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
-- Events
-- ============================================================================

-- Initialize the database on player login.
EventManager:Once(E.Wow.PlayerLogin, function()
  local db = Addon.DethsDBLib(AddonName, defaults)
  setmetatable(DB, { __index = db })

  Addon:ReformatDB()

  EventManager:Fire(E.DatabaseReady)
  EventManager:Fire(E.ProfileChanged)
end)
