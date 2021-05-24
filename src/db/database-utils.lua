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

-- Ensures that the table [t] contains a value for the key [k]. If `t[k]` does
-- not exist, or does not match the [default] value type, it is assigned the
-- [default] value.
--
-- Recurses if `t[k]` and [default] are tables.
function DatabaseUtils:EnsureKey(t, k, default)
  if type(t[k]) == "table" and type(default) == "table" then
    for dk in pairs(default) do
      self:EnsureKey(t[k], dk, default[dk])
    end
  elseif type(t[k]) ~= type(default) then
    t[k] = default
  end
end

-- Returns default global table.
function DatabaseUtils:Global()
  return {
    version = GlobalVersioner.DEFAULT_VERSION,

    minimapIcon = { hide = false },
    showItemTooltip = true,
    showMerchantButton = true,

    sell = {
      frame = { point = nil },
      inclusions = {},
      exclusions = {}
    },

    destroy = {
      frame = { point = nil },
      inclusions = {},
      exclusions = {}
    }
  }
end

-- Returns default profile table.
function DatabaseUtils:Profile()
  return {
    version = ProfileVersioner.DEFAULT_VERSION,

    general = {
      chat = {
        enabled = true,
        verbose = false,
        reason = false,
        sell = true,
        destroy = true,
        frame = _G.DEFAULT_CHAT_FRAME:GetName()
      },
      autoRepair = false,
      useGuildRepair = true,
    },

    sell = {
      auto = false,
      autoOpen = false,
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
        itemLevelRange = {
          enabled = false,
          min = Consts.ITEM_LEVEL_RANGE_MIN,
          max = Consts.ITEM_LEVEL_RANGE_MIN
        }
      },

      ignore = {
        battlePets = true,
        bindsWhenEquipped = true,
        consumables = true,
        cosmetic = true,
        equipmentSets = true,
        gems = true,
        glyphs = true,
        itemEnhancements = true,
        miscellaneous = true,
        questItems = true,
        readable = true,
        reagents = true,
        recipes = true,
        soulbound = true,
        tradeable = true,
        tradeGoods = true,
      },

      inclusions = {},
      exclusions = {}
    },

    destroy = {
      autoOpen = {
        enabled = false,
        value = Consts.DESTROY_AUTO_SLIDER_MIN,
      },

      autoStart = {
        enabled = false,
        value = Consts.DESTROY_AUTO_SLIDER_MIN,
      },

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
        itemLevelRange = {
          enabled = false,
          min = Consts.ITEM_LEVEL_RANGE_MIN,
          max = Consts.ITEM_LEVEL_RANGE_MIN
        }
      },

      ignore = {
        battlePets = true,
        bindsWhenEquipped = true,
        consumables = true,
        cosmetic = true,
        equipmentSets = true,
        gems = true,
        glyphs = true,
        itemEnhancements = true,
        miscellaneous = true,
        questItems = true,
        readable = true,
        reagents = true,
        recipes = true,
        soulbound = true,
        tradeable = true,
        tradeGoods = true,
      },

      inclusions = {},
      exclusions = {}
    }
  }
end
