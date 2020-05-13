local _, Addon = ...
local DB = Addon.DB
local General = Addon.UI.Groups.General
local L = Addon.Libs.L
local MerchantButton = Addon.UI.MerchantButton
local MinimapIcon = Addon.MinimapIcon
local Widgets = Addon.UI.Widgets

function General:Create(parent)
  Widgets:Heading(parent, L.GENERAL_TEXT)
  self:AddGlobal(parent)
  self:AddChat(parent)
  self:AddRepairing(parent)
end

function General:AddGlobal(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.GLOBAL_TEXT,
    fullWidth = true
  })

  -- Item Tooltip
  Widgets:CheckBox({
    parent = parent,
    label = L.ITEM_TOOLTIP_TEXT,
    tooltip = L.ITEM_TOOLTIP_TOOLTIP,
    get = function() return DB.Global.showItemTooltip end,
    set = function(value) DB.Global.showItemTooltip = value end
  })

  -- Merchant Button
  Widgets:CheckBox({
    parent = parent,
    label = L.MERCHANT_CHECKBUTTON_TEXT,
    tooltip = L.MERCHANT_CHECKBUTTON_TOOLTIP,
    get = function() return DB.Global.showMerchantButton end,
    set = function(value)
      DB.Global.showMerchantButton = value
      MerchantButton:Update()
    end
  })

  -- Minimap Button
  Widgets:CheckBox({
    parent = parent,
    label = L.MINIMAP_CHECKBUTTON_TEXT,
    tooltip = L.MINIMAP_CHECKBUTTON_TOOLTIP,
    get = function() return not DB.Global.minimapIcon.hide end,
    set = function() MinimapIcon:Toggle() end
  })
end

function General:AddChat(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.CHAT_TEXT,
    fullWidth = true
  })

  -- Silent Mode
  Widgets:CheckBox({
    parent = parent,
    label = L.SILENT_MODE_TEXT,
    tooltip = L.SILENT_MODE_TOOLTIP,
    get = function() return DB.Profile.general.silentMode end,
    set = function(value) DB.Profile.general.silentMode = value end
  })

  -- Verbose Mode
  Widgets:CheckBox({
    parent = parent,
    label = L.VERBOSE_MODE_TEXT,
    tooltip = L.VERBOSE_MODE_TOOLTIP,
    get = function() return DB.Profile.general.verboseMode end,
    set = function(value) DB.Profile.general.verboseMode = value end
  })
end

function General:AddRepairing(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.REPAIRING_TEXT,
    fullWidth = true
  })

  -- Auto Repair
  Widgets:CheckBox({
    parent = parent,
    label = L.AUTO_REPAIR_TEXT,
    tooltip = L.AUTO_REPAIR_TOOLTIP,
    get = function() return DB.Profile.general.autoRepair end,
    set = function(value) DB.Profile.general.autoRepair = value end
  })

  -- Use Guild Repair
  if Addon.IS_RETAIL then
    Widgets:CheckBox({
      parent = parent,
      label = L.USE_GUILD_REPAIR_TEXT,
      tooltip = L.USE_GUILD_REPAIR_TOOLTIP,
      get = function() return DB.Profile.general.useGuildRepair end,
      set = function(value) DB.Profile.general.useGuildRepair = value end
    })
  end
end
