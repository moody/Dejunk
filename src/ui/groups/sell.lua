local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local Sell = Addon.UI.Groups.Sell
local Utils = Addon.Utils
local Widgets = Addon.UI.Widgets

function Sell:Create(parent)
  Widgets:Heading(parent, L.SELL_TEXT)
  self:AddGeneral(parent)
  self:AddByQuality(parent)
  self:AddByType(parent)
  self:AddIgnore(parent)
end

function Sell:AddGeneral(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.GENERAL_TEXT,
    fullWidth = true
  })

  -- Auto Sell
  Widgets:CheckBox({
    parent = parent,
    label = L.AUTO_SELL_TEXT,
    tooltip = L.AUTO_SELL_TOOLTIP,
    get = function() return DB.Profile.sell.auto end,
    set = function(value) DB.Profile.sell.auto = value end
  })

  -- Auto Open
  Widgets:CheckBox({
    parent = parent,
    label = L.AUTO_OPEN_TEXT,
    tooltip = L.AUTO_OPEN_SELL_TOOLTIP,
    get = function() return DB.Profile.sell.autoOpen end,
    set = function(value) DB.Profile.sell.autoOpen = value end
  })

  -- Safe Mode
  Widgets:CheckBox({
    parent = parent,
    label = L.SAFE_MODE_TEXT,
    tooltip = L.SAFE_MODE_TOOLTIP:format(Consts.SAFE_MODE_MAX),
    get = function() return DB.Profile.sell.safeMode end,
    set = function(value) DB.Profile.sell.safeMode = value end
  })

  -- Below Price
  Widgets:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.BELOW_PRICE_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.SELL_BELOW_PRICE_TOOLTIP),
      get = function() return DB.Profile.sell.belowPrice.enabled end,
      set = function(value) DB.Profile.sell.belowPrice.enabled = value end
    },
    slider = {
      label = GetCoinTextureString(DB.Profile.sell.belowPrice.value),
      value = DB.Profile.sell.belowPrice.value,
      min = Consts.SELL_BELOW_PRICE_MIN,
      max = Consts.SELL_BELOW_PRICE_MAX,
      step = Consts.SELL_BELOW_PRICE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.sell.belowPrice.value = value
        this:SetLabel(GetCoinTextureString(DB.Profile.sell.belowPrice.value))
      end
    }
  })
end

function Sell:AddByQuality(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.BY_QUALITY_TEXT,
    fullWidth = true
  })

  -- Poor
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.sell.byQuality.poor end,
    set = function(value) DB.Profile.sell.byQuality.poor = value end
  })

  -- Common
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.sell.byQuality.common end,
    set = function(value) DB.Profile.sell.byQuality.common = value end
  })

  -- Uncommon
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.sell.byQuality.uncommon end,
    set = function(value) DB.Profile.sell.byQuality.uncommon = value end
  })

  -- Rare
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.sell.byQuality.rare end,
    set = function(value) DB.Profile.sell.byQuality.rare = value end
  })

  -- Epic
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.sell.byQuality.epic end,
    set = function(value) DB.Profile.sell.byQuality.epic = value end
  })
end

function Sell:AddByType(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.BY_TYPE_TEXT,
    fullWidth = true
  })

  -- Unsuitable Equipment
  Widgets:CheckBox({
    parent = parent,
    label = L.SELL_UNSUITABLE_TEXT,
    tooltip =
      Addon.IS_RETAIL and
      L.SELL_UNSUITABLE_TOOLTIP or
      L.SELL_UNSUITABLE_TOOLTIP_CLASSIC,
    get = function() return DB.Profile.sell.byType.unsuitable end,
    set = function(value) DB.Profile.sell.byType.unsuitable = value end
  })

  -- Item Level Range.
  Widgets:CheckBoxSliderRange({
    parent = parent,
    checkBox = {
      label = L.ITEM_LEVEL_RANGE_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_TOOLTIP,
      get = function() return DB.Profile.sell.byType.itemLevelRange.enabled end,
      set = function(value)
        DB.Profile.sell.byType.itemLevelRange.enabled = value
      end
    },
    minSlider = {
      label = L.MINIMUM_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_MIN_TOOLTIP,
      value = DB.Profile.sell.byType.itemLevelRange.min,
      min = Consts.ITEM_LEVEL_RANGE_MIN,
      max = DB.Profile.sell.byType.itemLevelRange.max,
      step = Consts.ITEM_LEVEL_RANGE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.sell.byType.itemLevelRange.min = value
      end
    },
    maxSlider = {
      label = L.MAXIMUM_TEXT,
      tooltip = L.ITEM_LEVEL_RANGE_MAX_TOOLTIP,
      value = DB.Profile.sell.byType.itemLevelRange.max,
      min = DB.Profile.sell.byType.itemLevelRange.min,
      max = Consts.ITEM_LEVEL_RANGE_MAX,
      step = Consts.ITEM_LEVEL_RANGE_STEP,
      onValueChanged = function(this, event, value)
        DB.Profile.sell.byType.itemLevelRange.max = value
      end
    },
  })
end

function Sell:AddIgnore(parent)
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
        get = function() return DB.Profile.sell.ignore.battlePets end,
        set = function(value) DB.Profile.sell.ignore.battlePets = value end
      })
    end

    -- Consumables
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_CONSUMABLES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_CONSUMABLES_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.consumables end,
      set = function(value) DB.Profile.sell.ignore.consumables = value end
    })

    if not Addon.IS_CLASSIC then
      -- Gems
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GEMS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GEMS_TOOLTIP),
        get = function() return DB.Profile.sell.ignore.gems end,
        set = function(value) DB.Profile.sell.ignore.gems = value end
      })
    end

    if Addon.IS_RETAIL then
      -- Glyphs
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GLYPHS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GLYPHS_TOOLTIP),
        get = function() return DB.Profile.sell.ignore.glyphs end,
        set = function(value) DB.Profile.sell.ignore.glyphs = value end
      })
    end

    -- Item Enhancements
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_ITEM_ENHANCEMENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.itemEnhancements end,
      set = function(value) DB.Profile.sell.ignore.itemEnhancements = value end
    })

    -- Miscellaneous
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_MISCELLANEOUS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_MISCELLANEOUS_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.miscellaneous end,
      set = function(value) DB.Profile.sell.ignore.miscellaneous = value end
    })

    -- Reagents
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_REAGENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_REAGENTS_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.reagents end,
      set = function(value) DB.Profile.sell.ignore.reagents = value end
    })

    -- Recipes
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_RECIPES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_RECIPES_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.recipes end,
      set = function(value) DB.Profile.sell.ignore.recipes = value end
    })

    -- Trade Goods
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_TRADE_GOODS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_TRADE_GOODS_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.tradeGoods end,
      set = function(value) DB.Profile.sell.ignore.tradeGoods = value end
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
      get = function() return DB.Profile.sell.ignore.bindsWhenEquipped end,
      set = function(value) DB.Profile.sell.ignore.bindsWhenEquipped = value end
    })

    -- Cosmetic
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_COSMETIC_TEXT,
      tooltip = L.IGNORE_COSMETIC_TOOLTIP,
      get = function() return DB.Profile.sell.ignore.cosmetic end,
      set = function(value) DB.Profile.sell.ignore.cosmetic = value end
    })

    -- Equipment Sets
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_EQUIPMENT_SETS_TEXT,
        tooltip = L.IGNORE_EQUIPMENT_SETS_TOOLTIP,
        get = function() return DB.Profile.sell.ignore.equipmentSets end,
        set = function(value) DB.Profile.sell.ignore.equipmentSets = value end
      })
    end

    -- Quest Items
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_QUEST_ITEMS_TEXT,
      tooltip = L.IGNORE_QUEST_ITEMS_TOOLTIP,
      get = function() return DB.Profile.sell.ignore.questItems end,
      set = function(value) DB.Profile.sell.ignore.questItems = value end
    })

    -- Readable
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_READABLE_TEXT,
      tooltip = L.IGNORE_READABLE_TOOLTIP,
      get = function() return DB.Profile.sell.ignore.readable end,
      set = function(value) DB.Profile.sell.ignore.readable = value end
    })

    -- Soulbound
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_SOULBOUND_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_SOULBOUND_TOOLTIP),
      get = function() return DB.Profile.sell.ignore.soulbound end,
      set = function(value) DB.Profile.sell.ignore.soulbound = value end
    })

    -- Tradeable
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_TRADEABLE_TEXT,
        tooltip = L.IGNORE_TRADEABLE_TOOLTIP,
        get = function() return DB.Profile.sell.ignore.tradeable end,
        set = function(value) DB.Profile.sell.ignore.tradeable = value end
      })
    end
  end
end
