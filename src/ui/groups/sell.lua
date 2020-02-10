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
    get = function() return DB.Profile.AutoSell end,
    set = function(value) DB.Profile.AutoSell = value end
  })

  -- Safe Mode
  Widgets:CheckBox({
    parent = parent,
    label = L.SAFE_MODE_TEXT,
    tooltip = L.SAFE_MODE_TOOLTIP:format(Consts.SAFE_MODE_MAX),
    get = function() return DB.Profile.SafeMode end,
    set = function(value) DB.Profile.SafeMode = value end
  })

  -- Below Price
  Widgets:CheckBoxSlider({
    parent = parent,
    checkBox = {
      label = L.SELL_BELOW_PRICE_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.SELL_BELOW_PRICE_TOOLTIP),
      get = function() return DB.Profile.SellBelowPrice.Enabled end,
      set = function(value) DB.Profile.SellBelowPrice.Enabled = value end
    },
    slider = {
      label = GetCoinTextureString(DB.Profile.SellBelowPrice.Value),
      value = DB.Profile.SellBelowPrice.Value,
      min = Consts.SELL_BELOW_PRICE_MIN,
      max = Consts.SELL_BELOW_PRICE_MAX,
      step = Consts.SELL_BELOW_PRICE_STEP,
      onValueChanged = function(self, event, value)
        DB.Profile.SellBelowPrice.Value = value
        self:SetLabel(GetCoinTextureString(DB.Profile.SellBelowPrice.Value))
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
    get = function() return DB.Profile.SellPoor end,
    set = function(value) DB.Profile.SellPoor = value end
  })

  -- Common
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellCommon end,
    set = function(value) DB.Profile.SellCommon = value end
  })

  -- Uncommon
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellUncommon end,
    set = function(value) DB.Profile.SellUncommon = value end
  })

  -- Rare
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellRare end,
    set = function(value) DB.Profile.SellRare = value end
  })

  -- Epic
  Widgets:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellEpic end,
    set = function(value) DB.Profile.SellEpic = value end
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
    get = function() return DB.Profile.SellUnsuitable end,
    set = function(value) DB.Profile.SellUnsuitable = value end
  })

  -- Below Average ILVL
  if Addon.IS_RETAIL then
    Widgets:CheckBoxSlider({
      parent = parent,
      checkBox = {
        label = L.SELL_BELOW_AVERAGE_ILVL_TEXT,
        tooltip = L.SELL_BELOW_AVERAGE_ILVL_TOOLTIP,
        get = function() return DB.Profile.SellBelowAverageILVL.Enabled end,
        set = function(value) DB.Profile.SellBelowAverageILVL.Enabled = value end
      },
      slider = {
        label = L.ITEM_LEVELS_TEXT,
        value = DB.Profile.SellBelowAverageILVL.Value,
        min = Consts.SELL_BELOW_AVERAGE_ILVL_MIN,
        max = Consts.SELL_BELOW_AVERAGE_ILVL_MAX,
        step = Consts.SELL_BELOW_AVERAGE_ILVL_STEP,
        onValueChanged = function(self, event, value)
          DB.Profile.SellBelowAverageILVL.Value = value
        end
      }
    })
  end
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
        get = function() return DB.Profile.IgnoreBattlePets end,
        set = function(value) DB.Profile.IgnoreBattlePets = value end
      })
    end

    -- Consumables
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_CONSUMABLES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_CONSUMABLES_TOOLTIP),
      get = function() return DB.Profile.IgnoreConsumables end,
      set = function(value) DB.Profile.IgnoreConsumables = value end
    })

    if Addon.IS_RETAIL then
      -- Gems
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GEMS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GEMS_TOOLTIP),
        get = function() return DB.Profile.IgnoreGems end,
        set = function(value) DB.Profile.IgnoreGems = value end
      })

      -- Glyphs
      Widgets:CheckBox({
        parent = byCategory,
        label = L.IGNORE_GLYPHS_TEXT,
        tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_GLYPHS_TOOLTIP),
        get = function() return DB.Profile.IgnoreGlyphs end,
        set = function(value) DB.Profile.IgnoreGlyphs = value end
      })
    end

    -- Item Enhancements
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_ITEM_ENHANCEMENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP),
      get = function() return DB.Profile.IgnoreItemEnhancements end,
      set = function(value) DB.Profile.IgnoreItemEnhancements = value end
    })

    -- Miscellaneous
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_MISCELLANEOUS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_MISCELLANEOUS_TOOLTIP),
      get = function() return DB.Profile.IgnoreMiscellaneous end,
      set = function(value) DB.Profile.IgnoreMiscellaneous = value end
    })

    -- Reagents
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_REAGENTS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_REAGENTS_TOOLTIP),
      get = function() return DB.Profile.IgnoreReagents end,
      set = function(value) DB.Profile.IgnoreReagents = value end
    })

    -- Recipes
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_RECIPES_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_RECIPES_TOOLTIP),
      get = function() return DB.Profile.IgnoreRecipes end,
      set = function(value) DB.Profile.IgnoreRecipes = value end
    })

    -- Trade Goods
    Widgets:CheckBox({
      parent = byCategory,
      label = L.IGNORE_TRADE_GOODS_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_TRADE_GOODS_TOOLTIP),
      get = function() return DB.Profile.IgnoreTradeGoods end,
      set = function(value) DB.Profile.IgnoreTradeGoods = value end
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
      get = function() return DB.Profile.IgnoreBindsWhenEquipped end,
      set = function(value) DB.Profile.IgnoreBindsWhenEquipped = value end
    })

    -- Cosmetic
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_COSMETIC_TEXT,
      tooltip = L.IGNORE_COSMETIC_TOOLTIP,
      get = function() return DB.Profile.IgnoreCosmetic end,
      set = function(value) DB.Profile.IgnoreCosmetic = value end
    })

    -- Equipment Sets
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_EQUIPMENT_SETS_TEXT,
        tooltip = L.IGNORE_EQUIPMENT_SETS_TOOLTIP,
        get = function() return DB.Profile.IgnoreEquipmentSets end,
        set = function(value) DB.Profile.IgnoreEquipmentSets = value end
      })
    end

    -- Quest Items
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_QUEST_ITEMS_TEXT,
      tooltip = L.IGNORE_QUEST_ITEMS_TOOLTIP,
      get = function() return DB.Profile.IgnoreQuestItems end,
      set = function(value) DB.Profile.IgnoreQuestItems = value end
    })

    -- Readable
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_READABLE_TEXT,
      tooltip = L.IGNORE_READABLE_TOOLTIP,
      get = function() return DB.Profile.IgnoreReadable end,
      set = function(value) DB.Profile.IgnoreReadable = value end
    })

    -- Soulbound
    Widgets:CheckBox({
      parent = byType,
      label = L.IGNORE_SOULBOUND_TEXT,
      tooltip = Utils:DoesNotApplyToPoor(L.IGNORE_SOULBOUND_TOOLTIP),
      get = function() return DB.Profile.IgnoreSoulbound end,
      set = function(value) DB.Profile.IgnoreSoulbound = value end
    })

    -- Tradeable
    if Addon.IS_RETAIL then
      Widgets:CheckBox({
        parent = byType,
        label = L.IGNORE_TRADEABLE_TEXT,
        tooltip = L.IGNORE_TRADEABLE_TOOLTIP,
        get = function() return DB.Profile.IgnoreTradeable end,
        set = function(value) DB.Profile.IgnoreTradeable = value end
      })
    end
  end
end
