local _, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DB = Addon.DB

local conversions = {}

-- Updates and constrains database values.
function Addon:ReformatDB()
  assert(DB._svar, "SavedVariables not loaded")

  for _, conversion in ipairs(conversions) do
    -- Convert global data
    if type(conversion.global) == "function" then
      conversion.global(DB._svar.Global)
    end

    -- Convert profile data
    if type(conversion.profile) == "function" then
      for _, profile in pairs(DB._svar.Profiles) do
        conversion.profile(profile)
      end
    end
  end
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--[[
  Moves kv-pairs from one table to another.

  @param {table} from
  @param {table} to
  @param {table} keyMap = {
    ["fromKey"] = "toKey"
  }
--]]
local function moveKeys(from, to, keyMap)
  for fromKey, toKey in pairs(keyMap) do
    if from[fromKey] ~= nil then
      to[toKey] = from[fromKey]
      from[fromKey] = nil
    end
  end
end

-- ============================================================================
-- DestroyPriceThreshold -> destroy.belowPrice
-- ============================================================================

conversions[#conversions+1] = {
  profile = function(profile)
    if type(profile.DestroyUsePriceThreshold) == "boolean" then
      profile.destroy.belowPrice.enabled = profile.DestroyUsePriceThreshold
    end

    if type(profile.DestroyPriceThreshold) == "table" then
      profile.destroy.belowPrice.value =
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

conversions[#conversions+1] = {
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

conversions[#conversions+1] = (function()
  local keys = {
    sliderTable = {
      Enabled = "enabled",
      Value = "value",
    },

    global = {
      Minimap = "minimapIcon",
      ItemTooltip = "showItemTooltip",
      MerchantButton = "showMerchantButton"
    },

    general = {
      SilentMode = "silentMode",
      VerboseMode = "verboseMode",
      AutoRepair = "autoRepair",
      UseGuildRepair = "useGuildRepair"
    },

    sell = {
      general = {
        AutoSell = "auto",
        SafeMode = "safeMode",
        Inclusions = "inclusions",
        Exclusions = "exclusions",
      },

      byQuality = {
        SellPoor = "poor",
        SellCommon = "common",
        SellUncommon = "uncommon",
        SellRare = "rare",
        SellEpic = "epic",
      },

      byType = {
        SellUnsuitable = "unsuitable"
      },

      ignore = {
        IgnoreBattlePets = "battlePets",
        IgnoreBindsWhenEquipped = "bindsWhenEquipped",
        IgnoreConsumables = "consumables",
        IgnoreCosmetic = "cosmetic",
        IgnoreEquipmentSets = "equipmentSets",
        IgnoreGems = "gems",
        IgnoreGlyphs = "glyphs",
        IgnoreItemEnhancements = "itemEnhancements",
        IgnoreMiscellaneous = "miscellaneous",
        IgnoreQuestItems = "questItems",
        IgnoreReadable = "readable",
        IgnoreReagents = "reagents",
        IgnoreRecipes = "recipes",
        IgnoreSoulbound = "soulbound",
        IgnoreTradeable = "tradeable",
        IgnoreTradeGoods = "tradeGoods"
      }
    },

    destroy = {
      general = {
        AutoDestroy = "auto",
        Destroyables = "inclusions",
        Undestroyables = "exclusions",
      },

      byQuality = {
        DestroyPoor = "poor",
        DestroyCommon = "common",
        DestroyUncommon = "uncommon",
        DestroyRare = "rare",
        DestroyEpic = "epic",
      },

      byType = {
        DestroyPetsAlreadyCollected = "petsAlreadyCollected",
        DestroyToysAlreadyCollected = "toysAlreadyCollected",
      },

      ignore = {
        DestroyIgnoreBattlePets = "battlePets",
        DestroyIgnoreBindsWhenEquipped = "bindsWhenEquipped",
        DestroyIgnoreConsumables = "consumables",
        DestroyIgnoreCosmetic = "cosmetic",
        DestroyIgnoreEquipmentSets = "equipmentSets",
        DestroyIgnoreGems = "gems",
        DestroyIgnoreGlyphs = "glyphs",
        DestroyIgnoreItemEnhancements = "itemEnhancements",
        DestroyIgnoreMiscellaneous = "miscellaneous",
        DestroyIgnoreQuestItems = "questItems",
        DestroyIgnoreReadable = "readable",
        DestroyIgnoreReagents = "reagents",
        DestroyIgnoreRecipes = "recipes",
        DestroyIgnoreSoulbound = "soulbound",
        DestroyIgnoreTradeable = "tradeable",
        DestroyIgnoreTradeGoods = "tradeGoods"
      }
    },
  }

  return {
    global = function(global)
      moveKeys(global, global, keys.global)
    end,

    profile = (function()
      local function general(profile)
        moveKeys(profile, profile.general, keys.general)
      end

      local function sell(profile)
        -- General
        moveKeys(profile, profile.sell, keys.sell.general)

        if type(profile.SellBelowPrice) == "table" then
          moveKeys(
            profile.SellBelowPrice,
            profile.sell.belowPrice,
            keys.sliderTable
          )
          profile.SellBelowPrice = nil
        end

        -- By quality
        moveKeys(profile, profile.sell.byQuality, keys.sell.byQuality)

        -- By type
        moveKeys(profile, profile.sell.byType, keys.sell.byType)

        if type(profile.SellBelowAverageILVL) == "table" then
          moveKeys(
            profile.SellBelowAverageILVL,
            profile.sell.byType.belowAverageItemLevel,
            keys.sliderTable
          )
          profile.SellBelowAverageILVL = nil
        end

        -- Ignore
        moveKeys(profile, profile.sell.ignore, keys.sell.ignore)
      end

      local function destroy(profile)
        -- General
        moveKeys(profile, profile.destroy, keys.destroy.general)

        if type(profile.DestroyBelowPrice) == "table" then
          moveKeys(
            profile.DestroyBelowPrice,
            profile.destroy.belowPrice,
            keys.sliderTable
          )
          profile.DestroyBelowPrice = nil
        end

        if type(profile.DestroySaveSpace) == "table" then
          moveKeys(
            profile.DestroySaveSpace,
            profile.destroy.saveSpace,
            keys.sliderTable
          )
          profile.DestroySaveSpace = nil
        end

        -- By quality
        moveKeys(profile, profile.destroy.byQuality, keys.destroy.byQuality)

        -- By type
        moveKeys(profile, profile.destroy.byType, keys.destroy.byType)

        if type(profile.DestroyExcessSoulShards) == "table" then
          moveKeys(
            profile.DestroyExcessSoulShards,
            profile.destroy.byType.excessSoulShards,
            keys.sliderTable
          )
          profile.DestroyExcessSoulShards = nil
        end

        -- Ignore
        moveKeys(profile, profile.destroy.ignore, keys.destroy.ignore)
      end

      return function(profile)
        general(profile)
        sell(profile)
        destroy(profile)
      end
    end)(),
  }
end)()

-- ============================================================================
-- Clamp min-max values
-- ============================================================================

conversions[#conversions+1] = {
  profile = function(profile)
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

    profile.destroy.saveSpace.value = Clamp(
      profile.destroy.saveSpace.value,
      Consts.DESTROY_SAVE_SPACE_MIN,
      Consts.DESTROY_SAVE_SPACE_MAX
    )
  end
}
