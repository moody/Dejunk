-- DB: provides addon modules easy access to saved variables.

local AddonName, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local E = Addon.Events
local EventManager = Addon.EventManager

-- Default database values
local defaults = {
  Global = {
    minimapIcon = { hide = false },
    showItemTooltip = true,
    showMerchantButton = true
  },
  Profile = {
    general = {
      silentMode = false,
      verboseMode = true,
      autoRepair = false,
      useGuildRepair = true,
    },

    sell = {
      auto = false,
      safeMode = true,
      belowPrice = {
        enabled = false,
        value = Consts.SELL_BELOW_PRICE_MIN
      },

      byQuality = {
        poor = true,
        common = false,
        uncommon = false,
        rare = false,
        epic = false,
      },

      byType = {
        unsuitable = false,
        belowAverageItemLevel = {
          enabled = false,
          value = Consts.SELL_BELOW_AVERAGE_ILVL_MIN
        },
      },

      ignore = {
        battlePets = false,
        bindsWhenEquipped = false,
        consumables = false,
        cosmetic = false,
        equipmentSets = false,
        gems = false,
        glyphs = false,
        itemEnhancements = false,
        miscellaneous = false,
        questItems = false,
        readable = false,
        reagents = false,
        recipes = false,
        soulbound = false,
        tradeable = false,
        tradeGoods = false,
      },
    },

    destroy = {
      auto = false,
      belowPrice = {
        enabled = false,
        value = Consts.DESTROY_BELOW_PRICE_MIN
      },
      saveSpace = {
        enabled = false,
        value = Consts.DESTROY_SAVE_SPACE_MIN
      },

      byQuality = {
        poor = false,
        common = false,
        uncommon = false,
        rare = false,
        epic = false,
      },

      byType = {
        petsAlreadyCollected = false,
        toysAlreadyCollected = false,
        excessSoulShards = {
          enabled = false,
          value = Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN
        },
      },

      ignore = {
        battlePets = false,
        bindsWhenEquipped = false,
        consumables = false,
        cosmetic = false,
        equipmentSets = false,
        gems = false,
        glyphs = false,
        itemEnhancements = false,
        miscellaneous = false,
        questItems = false,
        readable = false,
        reagents = false,
        recipes = false,
        soulbound = false,
        tradeable = false,
        tradeGoods = false,
      },
    },

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
