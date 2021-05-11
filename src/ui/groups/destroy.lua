local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Destroy = Addon.UI.Groups.Destroy
local L = Addon.Libs.L
local Utils = Addon.Utils
local Widgets = Addon.UI.Widgets

-- Upvalues
local GetCoinTextureString = _G.GetCoinTextureString

function Destroy:Create(parent)
  Widgets:Heading(parent, L.DESTROY_TEXT)
  self:AddGeneral(parent)
  self:AddByQuality(parent)
  self:AddByType(parent)
  self:AddIgnore(parent)
end

function Destroy:AddGeneral(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.GENERAL_TEXT,
    fullWidth = true
  })

  -- Auto Open
  Widgets:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.AUTO_OPEN_TEXT,
      tooltip = L.AUTO_OPEN_DESTROY_TOOLTIP,
      get = function() return DB.Profile.destroy.autoOpen.enabled end,
      set = function(value) DB.Profile.destroy.autoOpen.enabled = value end
    },
    slider = {
      label = L.THRESHOLD_TEXT,
      tooltip = L.AUTO_OPTION_THRESHOLD_TOOLTIP:format(
        "|cFFFFD100"  .. L.AUTO_OPEN_TEXT .. "|r",
        "|cFFFFD100"  .. L.AUTO_OPEN_TEXT .. "|r"
      ),
      value = DB.Profile.destroy.autoOpen.value,
      min = Consts.DESTROY_AUTO_SLIDER_MIN,
      max = Consts.DESTROY_AUTO_SLIDER_MAX,
      step = Consts.DESTROY_AUTO_SLIDER_STEP,
      onValueChanged = function(_, event, value)
        DB.Profile.destroy.autoOpen.value = value
      end
    }
  })

  -- Auto Start
  if Addon.IS_CLASSIC then
    Widgets:CheckBoxSlider({
      parent = parent,
      checkBox = {
        label = L.AUTO_START_TEXT,
        tooltip = L.AUTO_START_DESTROY_TOOLTIP,
        get = function() return DB.Profile.destroy.autoStart.enabled end,
        set = function(value) DB.Profile.destroy.autoStart.enabled = value end
      },
      slider = {
        label = L.THRESHOLD_TEXT,
        tooltip = L.AUTO_OPTION_THRESHOLD_TOOLTIP:format(
          "|cFFFFD100"  .. L.AUTO_START_TEXT .. "|r",
          "|cFFFFD100"  .. L.AUTO_START_TEXT .. "|r"
        ),
        value = DB.Profile.destroy.autoStart.value,
        min = Consts.DESTROY_AUTO_SLIDER_MIN,
        max = Consts.DESTROY_AUTO_SLIDER_MAX,
        step = Consts.DESTROY_AUTO_SLIDER_STEP,
        onValueChanged = function(_, event, value)
          DB.Profile.destroy.autoStart.value = value
        end
      }
    })
  end

  -- Below Price
  Widgets:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.BELOW_PRICE_TEXT,
      tooltip = L.DESTROY_BELOW_PRICE_TOOLTIP,
      get = function() return DB.Profile.destroy.belowPrice.enabled end,
      set = function(value) DB.Profile.destroy.belowPrice.enabled = value end
    },
    slider = {
      label = GetCoinTextureString(DB.Profile.destroy.belowPrice.value),
      value = DB.Profile.destroy.belowPrice.value,
      min = Consts.DESTROY_BELOW_PRICE_MIN,
      max = Consts.DESTROY_BELOW_PRICE_MAX,
      step = Consts.DESTROY_BELOW_PRICE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.destroy.belowPrice.value = value
        this:SetLabel(GetCoinTextureString(DB.Profile.destroy.belowPrice.value))
      end
    }
  })
end

function Destroy:AddByQuality(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.BY_QUALITY_TEXT,
    fullWidth = true
  })

  -- Poor
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.destroy.byQuality.poor end,
    set = function(value) DB.Profile.destroy.byQuality.poor = value end
  })

  -- Common
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.destroy.byQuality.common end,
    set = function(value) DB.Profile.destroy.byQuality.common = value end
  })

  -- Uncommon
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.destroy.byQuality.uncommon end,
    set = function(value) DB.Profile.destroy.byQuality.uncommon = value end
  })

  -- Rare
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.destroy.byQuality.rare end,
    set = function(value) DB.Profile.destroy.byQuality.rare = value end
  })

  -- Epic
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic),
    tooltip = L.DESTROY_ALL_TOOLTIP,
    get = function() return DB.Profile.destroy.byQuality.epic end,
    set = function(value) DB.Profile.destroy.byQuality.epic = value end
  })
end

function Destroy:AddByType(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.BY_TYPE_TEXT,
    fullWidth = true
  })

  if Addon.IS_RETAIL then
    -- Pets already collected
    Widgets:CheckBox({
      parent = parent,
      label = L.DESTROY_PETS_ALREADY_COLLECTED_TEXT,
      tooltip = L.DESTROY_PETS_ALREADY_COLLECTED_TOOLTIP,
      get = function() return DB.Profile.destroy.byType.petsAlreadyCollected end,
      set = function(value) DB.Profile.destroy.byType.petsAlreadyCollected = value end
    })

    -- Toys already collected
    Widgets:CheckBox({
      parent = parent,
      label = L.DESTROY_TOYS_ALREADY_COLLECTED_TEXT,
      tooltip = L.DESTROY_TOYS_ALREADY_COLLECTED_TOOLTIP,
      get = function() return DB.Profile.destroy.byType.toysAlreadyCollected end,
      set = function(value) DB.Profile.destroy.byType.toysAlreadyCollected = value end
    })
  end

  -- Excess Soul Shards
  if Addon.IS_CLASSIC or Addon.IS_BC then
    Widgets:CheckBoxSlider({
      parent = parent,
      checkBox = {
        label = L.DESTROY_EXCESS_SOUL_SHARDS_TEXT,
        tooltip = L.DESTROY_EXCESS_SOUL_SHARDS_TOOLTIP,
        get = function() return DB.Profile.destroy.byType.excessSoulShards.enabled end,
        set = function(value)
          DB.Profile.destroy.byType.excessSoulShards.enabled = value
        end
      },
      slider = {
        label = L.DESTROY_EXCESS_SOUL_SHARDS_SLIDER_LABEL,
        value = DB.Profile.destroy.byType.excessSoulShards.value,
        min = Consts.DESTROY_EXCESS_SOUL_SHARDS_MIN,
        max = Consts.DESTROY_EXCESS_SOUL_SHARDS_MAX,
        step = Consts.DESTROY_EXCESS_SOUL_SHARDS_STEP,
        onValueChanged = function(_, event, value)
          DB.Profile.destroy.byType.excessSoulShards.value = value
        end
      }
    })
  end

  -- Item Level Range.
  Widgets:CheckBoxSliderRange({
    parent = parent,
    checkBox = {
      label = L.ITEM_LEVEL_RANGE_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_TOOLTIP,
      get = function() return DB.Profile.destroy.byType.itemLevelRange.enabled end,
      set = function(value)
        DB.Profile.destroy.byType.itemLevelRange.enabled = value
      end
    },
    minSlider = {
      label = L.MINIMUM_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_MIN_TOOLTIP,
      value = DB.Profile.destroy.byType.itemLevelRange.min,
      min = Consts.ITEM_LEVEL_RANGE_MIN,
      max = DB.Profile.destroy.byType.itemLevelRange.max,
      step = Consts.ITEM_LEVEL_RANGE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.destroy.byType.itemLevelRange.min = value
      end
    },
    maxSlider = {
      label = L.MAXIMUM_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_MAX_TOOLTIP,
      value = DB.Profile.destroy.byType.itemLevelRange.max,
      min = DB.Profile.destroy.byType.itemLevelRange.min,
      max = Consts.ITEM_LEVEL_RANGE_MAX,
      step = Consts.ITEM_LEVEL_RANGE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.destroy.byType.itemLevelRange.max = value
      end
    },
  })
end

function Destroy:AddIgnore(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.IGNORE_TEXT,
    fullWidth = true
  })

  do -- By Category
    local byCategory = Widgets:InlineGroup({
      parent = parent,
      title = L.BY_CATEGORY_TEXT,
      fullWidth = true
    })

    -- Battle Pets
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_BATTLEPETS_TEXT,
        tooltip = L.IGNORE_BATTLEPETS_TOOLTIP,
        get = function() return DB.Profile.destroy.ignore.battlePets end,
        set = function(value) DB.Profile.destroy.ignore.battlePets = value end
      })
    end

    -- Consumables
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_CONSUMABLES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_CONSUMABLES_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.consumables end,
      set = function(value) DB.Profile.destroy.ignore.consumables = value end
    })

    if not Addon.IS_CLASSIC then
      -- Gems
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GEMS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GEMS_TOOLTIP),
        get = function() return DB.Profile.destroy.ignore.gems end,
        set = function(value) DB.Profile.destroy.ignore.gems = value end
      })
    end

    if Addon.IS_RETAIL then
      -- Glyphs
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GLYPHS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GLYPHS_TOOLTIP),
        get = function() return DB.Profile.destroy.ignore.glyphs end,
        set = function(value) DB.Profile.destroy.ignore.glyphs = value end
      })
    end

    -- Item Enhancements
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_ITEM_ENHANCEMENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.itemEnhancements end,
      set = function(value) DB.Profile.destroy.ignore.itemEnhancements = value end
    })

    -- Miscellaneous
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_MISCELLANEOUS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_MISCELLANEOUS_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.miscellaneous end,
      set = function(value) DB.Profile.destroy.ignore.miscellaneous = value end
    })

    -- Reagents
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_REAGENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_REAGENTS_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.reagents end,
      set = function(value) DB.Profile.destroy.ignore.reagents = value end
    })

    -- Recipes
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_RECIPES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_RECIPES_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.recipes end,
      set = function(value) DB.Profile.destroy.ignore.recipes = value end
    })

    -- Trade Goods
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_TRADE_GOODS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_TRADE_GOODS_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.tradeGoods end,
      set = function(value) DB.Profile.destroy.ignore.tradeGoods = value end
    })
  end

  do -- By Type
    local byType = Widgets:InlineGroup({
      parent = parent,
      title = L.BY_TYPE_TEXT,
      fullWidth = true
    })

    -- Binds When Equipped
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_BOE_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_BOE_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.bindsWhenEquipped end,
      set = function(value) DB.Profile.destroy.ignore.bindsWhenEquipped = value end
    })

    -- Cosmetic
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_COSMETIC_TEXT,
      tooltip = L.IGNORE_COSMETIC_TOOLTIP,
      get = function() return DB.Profile.destroy.ignore.cosmetic end,
      set = function(value) DB.Profile.destroy.ignore.cosmetic = value end
    })

    -- Equipment Sets
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_EQUIPMENT_SETS_TEXT,
        tooltip = L.IGNORE_EQUIPMENT_SETS_TOOLTIP,
        get = function() return DB.Profile.destroy.ignore.equipmentSets end,
        set = function(value) DB.Profile.destroy.ignore.equipmentSets = value end
      })
    end

    -- Quest Items
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_QUEST_ITEMS_TEXT,
      tooltip = L.IGNORE_QUEST_ITEMS_TOOLTIP,
      get = function() return DB.Profile.destroy.ignore.questItems end,
      set = function(value) DB.Profile.destroy.ignore.questItems = value end
    })

    -- Readable
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_READABLE_TEXT,
      tooltip = L.IGNORE_READABLE_TOOLTIP,
      get = function() return DB.Profile.destroy.ignore.readable end,
      set = function(value) DB.Profile.destroy.ignore.readable = value end
    })

    -- Soulbound
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_SOULBOUND_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_SOULBOUND_TOOLTIP),
      get = function() return DB.Profile.destroy.ignore.soulbound end,
      set = function(value) DB.Profile.destroy.ignore.soulbound = value end
    })

    -- Tradeable
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_TRADEABLE_TEXT,
        tooltip = L.IGNORE_TRADEABLE_TOOLTIP,
        get = function() return DB.Profile.destroy.ignore.tradeable end,
        set = function(value) DB.Profile.destroy.ignore.tradeable = value end
      })
    end
  end
end
