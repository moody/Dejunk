local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")
local StateManager = Addon:GetModule("StateManager")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- MainWindowOptions - Global
-- ============================================================================

--- Creates the panel of global-scoped options.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateGlobalOptionsPanel()
  local titleText = Colors.Blue(("%s (%s)"):format(L.OPTIONS_TEXT, Colors.White(L.GLOBAL)))
  local panel, container = OptionsBuilder:CreatePanel({
    titleText = titleText,
    titleJustify = "LEFT",
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(titleText)
      tooltip:AddLine(L.GLOBAL_OPTIONS_TOOLTIP)
    end
  })

  -- Safe destroy.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.SAFE_DESTROY_TEXT,
    descriptionText = L.SAFE_DESTROY_TOOLTIP,
    get = function() return StateManager:GetGlobalState().safeDestroy end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeDestroy(value)) end
  })

  -- Safe sell.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.SAFE_SELL_TEXT,
    descriptionText = L.SAFE_SELL_TOOLTIP,
    get = function() return StateManager:GetGlobalState().safeSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeSell(value)) end
  })

  -- Merchant button.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.MERCHANT_BUTTON_TEXT,
    descriptionText = L.MERCHANT_BUTTON_TOOLTIP,
    get = function() return StateManager:GetGlobalState().merchantButton end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setMerchantButton(value)) end,
    onRightClick = function()
      StateManager:Dispatch(ActionCreators.Global.points.merchantButton.reset())
    end,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(L.MERCHANT_BUTTON_TEXT)
      tooltip:AddLine(Addon:SubjectDescription(L.RIGHT_CLICK, L.RESET_POSITION))
    end
  })

  -- Minimap icon.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.MINIMAP_ICON_TEXT,
    descriptionText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end
  })

  -- Auto junk frame.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    descriptionText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoJunkFrame end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoJunkFrame(value)) end
  })

  -- Auto lootable frame.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.AUTO_LOOTABLE_FRAME_TEXT,
    descriptionText = L.AUTO_LOOTABLE_FRAME_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoLootableFrame end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoLootableFrame(value)) end
  })

  -- Chat messages.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.CHAT_MESSAGES_TEXT,
    descriptionText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetGlobalState().chatMessages end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setChatMessages(value)) end
  })

  -- Bag item tooltips.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    descriptionText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemTooltips end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemTooltips(value)) end
  })

  -- Bag item icons.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.BAG_ITEM_ICONS_TEXT,
    descriptionText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemIcons end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemIcons(value)) end
  })

  return panel
end
