local _, Addon = ...
local Chat = Addon.Chat
local DB = Addon.DB
local General = Addon.UI.Groups.General
local L = Addon.Libs.L
local MerchantButton = Addon.UI.MerchantButton
local MinimapIcon = Addon.MinimapIcon
local Widgets = Addon.UI.Widgets

function General:Create(parent)
  Widgets:Heading(parent, L.GENERAL_TEXT)
  self:AddGlobal(parent)
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

  do -- Chat
    local logging = Widgets:InlineGroup({
      parent = parent,
      title = L.CHAT_TEXT,
      fullWidth = true
    })

    -- Enabled
    Widgets:CheckBox({
      parent = logging,
      label = L.ENABLE_TEXT,
      tooltip = L.CHAT_ENABLE_TOOLTIP,
      get = function() return DB.Global.chat.enabled end,
      set = function(value) DB.Global.chat.enabled = value end
    })

    -- Verbose
    Widgets:CheckBox({
      parent = logging,
      label = L.VERBOSE_TEXT,
      tooltip = L.CHAT_VERBOSE_TOOLTIP,
      get = function() return DB.Global.chat.verbose end,
      set = function(value) DB.Global.chat.verbose = value end
    })

    -- Chat Frame
    Widgets:Dropdown({
      parent = logging,
      label = L.FRAME_TEXT,
      tooltip = L.CHAT_FRAME_TOOLTIP,
      list = Chat:GetDropdownList(),
      value = DB.Global.chat.frame,
      onValueChanged = function(_, event, key)
        local chatFrame = _G[key]
        if type(chatFrame) == "table" and chatFrame.AddMessage then
          DB.Global.chat.frame = key
          Chat:Print(L.CHAT_FRAME_CHANGED_MESSAGE)
        end
      end
    })
  end
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
