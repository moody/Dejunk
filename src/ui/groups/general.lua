local AddonName, Addon = ...
local L = Addon.Libs.L
local Utils = Addon.UI.Utils
local General = Addon.UI.Groups.General
local DB = Addon.DB

function General:Create(parent)
  Utils:Heading(parent, L.GENERAL_TEXT)

  self:AddGlobal(parent)
  self:AddChat(parent)
  self:AddRepairing(parent)
end

function General:AddGlobal(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.GLOBAL_TEXT,
    fullWidth = true
  })

  -- Item Tooltip
  Utils:CheckBox({
    parent = parent,
    label = L.ITEM_TOOLTIP_TEXT,
    tooltip = L.ITEM_TOOLTIP_TOOLTIP,
    get = function() return DB.Global.ItemTooltip end,
    set = function(value) DB.Global.ItemTooltip = value end
  })

  -- Minimap Button
  Utils:CheckBox({
    parent = parent,
    label = L.MINIMAP_CHECKBUTTON_TEXT,
    tooltip = L.MINIMAP_CHECKBUTTON_TOOLTIP,
    get = function() return not DB.Global.Minimap.hide end,
    set = function() Addon.MinimapIcon:Toggle() end
  })
end

function General:AddChat(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.CHAT_TEXT,
    fullWidth = true
  })

  -- Silent Mode
  Utils:CheckBox({
    parent = parent,
    label = L.SILENT_MODE_TEXT,
    tooltip = L.SILENT_MODE_TOOLTIP,
    get = function() return DB.Profile.SilentMode end,
    set = function(value) DB.Profile.SilentMode = value end
  })

  -- Verbose Mode
  Utils:CheckBox({
    parent = parent,
    label = L.VERBOSE_MODE_TEXT,
    tooltip = L.VERBOSE_MODE_TOOLTIP,
    get = function() return DB.Profile.VerboseMode end,
    set = function(value) DB.Profile.VerboseMode = value end
  })
end

function General:AddRepairing(parent)
  parent = Utils:InlineGroup({
    parent = parent,
    title = L.REPAIRING_TEXT,
    fullWidth = true
  })

  -- Auto Repair
  Utils:CheckBox({
    parent = parent,
    label = L.AUTO_REPAIR_TEXT,
    tooltip = L.AUTO_REPAIR_TOOLTIP,
    get = function() return DB.Profile.AutoRepair end,
    set = function(value) DB.Profile.AutoRepair = value end
  })

  -- Use Guild Repair
  if Addon.IS_RETAIL then
    Utils:CheckBox({
      parent = parent,
      label = L.USE_GUILD_REPAIR_TEXT,
      tooltip = L.USE_GUILD_REPAIR_TOOLTIP,
      get = function() return DB.Profile.UseGuildRepair end,
      set = function(value) DB.Profile.UseGuildRepair = value end
    })
  end
end
