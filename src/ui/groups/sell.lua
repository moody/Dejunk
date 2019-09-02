local AddonName, Addon = ...
local L = Addon.Libs.L
local AceGUI = Addon.Libs.AceGUI
local Utils = Addon.UI.Utils
local Sell = Addon.UI.Groups.Sell
local Consts = Addon.Consts
local DB = Addon.DB
local DCL = Addon.Libs.DCL

function Sell:Create(parent)
  Utils:Heading(parent, L.SELL_TEXT)

  self:AddGeneral(parent)
  self:AddByQuality(parent)
  self:AddByType(parent)
end

function Sell:AddGeneral(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.GENERAL_TEXT,
    fullWidth = true
  })

  -- Auto Sell
  Utils:CheckBox({
    parent = parent,
    label = L.AUTO_SELL_TEXT,
    tooltip = L.AUTO_SELL_TOOLTIP,
    get = function() return DB.Profile.AutoSell end,
    set = function(value) DB.Profile.AutoSell = value end
  })

  -- Safe Mode
  Utils:CheckBox({
    parent = parent,
    label = L.SAFE_MODE_TEXT,
    tooltip = L.SAFE_MODE_TOOLTIP:format(Consts.SAFE_MODE_MAX),
    get = function() return DB.Profile.SafeMode end,
    set = function(value) DB.Profile.SafeMode = value end
  })
end

function Sell:AddByQuality(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.BY_QUALITY_TEXT,
    fullWidth = true
  })

  -- Poor
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellPoor end,
    set = function(value) DB.Profile.SellPoor = value end
  })

  -- Common
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.COMMON_TEXT, DCL.Wow.Common),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellCommon end,
    set = function(value) DB.Profile.SellCommon = value end
  })

  -- Uncommon
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.UNCOMMON_TEXT, DCL.Wow.Uncommon),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellUncommon end,
    set = function(value) DB.Profile.SellUncommon = value end
  })

  -- Rare
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.RARE_TEXT, DCL.Wow.Rare),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellRare end,
    set = function(value) DB.Profile.SellRare = value end
  })

  -- Epic
  Utils:CheckBox({
    parent = parent,
    label = DCL:ColorString(L.EPIC_TEXT, DCL.Wow.Epic),
    tooltip = L.SELL_ALL_TOOLTIP,
    get = function() return DB.Profile.SellEpic end,
    set = function(value) DB.Profile.SellEpic = value end
  })
end

function Sell:AddByType(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.BY_TYPE_TEXT,
    fullWidth = true
  })

  -- Unsuitable Equipment
  Utils:CheckBox({
    parent = parent,
    label = L.SELL_UNSUITABLE_TEXT,
    tooltip = L.SELL_UNSUITABLE_TOOLTIP,
    get = function() return DB.Profile.SellUnsuitable end,
    set = function(value) DB.Profile.SellUnsuitable = value end
  })

  do -- Below Average Equipment
    local group = Utils:SimpleGroup({
      parent = parent,
      fullWidth = true
    })

    local slider = AceGUI:Create("Slider")
    slider:SetSliderValues(Consts.BELOW_AVERAGE_ILVL_MIN, Consts.BELOW_AVERAGE_ILVL_MAX, 1)
    slider:SetLabel(L.ITEM_LEVELS_TEXT)
    slider:SetValue(DB.Profile.SellBelowAverageILVL.Value)
    slider:SetDisabled(not DB.Profile.SellBelowAverageILVL.Enabled)
    slider:SetCallback("OnValueChanged", function(self, event, value)
      DB.Profile.SellBelowAverageILVL.Value = value
      self.editbox:ClearFocus()
    end)

    Utils:CheckBox({
      parent = group,
      label = L.SELL_BELOW_AVERAGE_ILVL_TEXT,
      tooltip = L.SELL_BELOW_AVERAGE_ILVL_TOOLTIP,
      get = function() return DB.Profile.SellBelowAverageILVL.Enabled end,
      set = function(value)
        DB.Profile.SellBelowAverageILVL.Enabled = value
        slider:SetDisabled(not value)
      end
    })

    group:AddChild(slider)
  end
end
