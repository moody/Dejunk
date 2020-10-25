local _, Addon = ...
local Chat = Addon.Chat
local Consts = Addon.Consts
local DatabaseUtils = Addon.DatabaseUtils
local DB = Addon.DB
local GlobalVersioner = Addon.GlobalVersioner
local ProfileVersioner = Addon.ProfileVersioner

-- ============================================================================
-- Functions
-- ============================================================================

function DatabaseUtils:Reformat()
  assert(DB._svar, "SavedVariables not loaded")

  do -- Format Global
    local success = pcall(function()
      GlobalVersioner:Run(DB._svar.Global)
    end)

    if not success then
      Chat:Debug('Global settings corrupted. Resetting to default.')
      local global = DatabaseUtils:Global()
      GlobalVersioner:Run(global)
      DB._svar.Global = global
    end
  end

  -- Format all profiles
  for key, profile in pairs(DB._svar.Profiles) do
    local success = pcall(function()
      ProfileVersioner:Run(profile)
    end)

    if not success then
      Chat:Debug(key, 'is corrupted. Resetting to default.')
      profile = DatabaseUtils:Profile()
      ProfileVersioner:Run(profile)
      DB._svar.Profiles[key] = profile
    end
  end
end

-- Returns default global table.
function DatabaseUtils:Global()
  return {
    version = GlobalVersioner.DEFAULT_VERSION,

    minimapIcon = { hide = false },
    showItemTooltip = true,
    showMerchantButton = true
  }
end

-- Returns default profile table.
function DatabaseUtils:Profile()
  return {
    version = ProfileVersioner.DEFAULT_VERSION,

    general = {
      chat = {
        enabled = true,
        verbose = true,
        reason = false,
        frame = _G.DEFAULT_CHAT_FRAME:GetName()
      },
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

      inclusions = {},
      exclusions = {}
    },

    destroy = {
      auto = false,
      autoSlider = Consts.DESTROY_AUTO_SLIDER_MIN,
      belowPrice = {
        enabled = false,
        value = Consts.DESTROY_BELOW_PRICE_MIN
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

      inclusions = {},
      exclusions = {}
    }
  }
end
