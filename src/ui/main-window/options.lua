local _, Addon = ...
local Actions = Addon:GetModule("Actions") ---@type Actions
local Colors = Addon:GetModule("Colors") ---@type Colors
local L = Addon:GetModule("Locale") ---@type Locale
local MinimapIcon = Addon:GetModule("MinimapIcon") ---@type MinimapIcon
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager") ---@type StateManager

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

--- Initializes options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:Initialize(optionsFrame)
  -- ============================================================================
  -- Global
  -- ============================================================================

  -- Heading.
  optionsFrame:AddOptionHeading({ text = L.GLOBAL })

  -- Minimap icon.
  optionsFrame:AddOptionButton({
    labelText = L.MINIMAP_ICON_TEXT,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end
  })

  -- ============================================================================
  -- Per Character
  -- ============================================================================

  -- Heading.
  optionsFrame:AddOptionHeading({ text = L.CHARACTER })

  -- Character specific settings.
  optionsFrame:AddOptionButton({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return StateManager:GetPercharState().characterSpecificSettings end,
    set = function() StateManager:GetStore():Dispatch(Actions:ToggleCharacterSpecificSettings()) end
  })

  -- ============================================================================
  -- Dynamic
  -- ============================================================================

  -- Heading.
  optionsFrame:AddOptionHeading({ text = L.DYNAMIC })

  -- Chat messages.
  optionsFrame:AddOptionButton({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetCurrentState().chatMessages end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetChatMessages(value)) end
  })

  -- Bag item icons.
  optionsFrame:AddOptionButton({
    labelText = L.BAG_ITEM_ICONS_TEXT,
    tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().itemIcons end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemIcons(value)) end
  })

  -- Bag item tooltips.
  optionsFrame:AddOptionButton({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().itemTooltips end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemTooltips(value)) end
  })

  -- Merchant button.
  optionsFrame:AddOptionButton({
    labelText = L.MERCHANT_BUTTON_TEXT,
    tooltipText = L.MERCHANT_BUTTON_TOOLTIP,
    get = function() return StateManager:GetCurrentState().merchantButton end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetMerchantButton(value)) end
  })

  -- Auto junk frame.
  optionsFrame:AddOptionButton({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoJunkFrame end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoJunkFrame(value)) end
  })

  -- Auto repair.
  optionsFrame:AddOptionButton({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoRepair end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoRepair(value)) end
  })

  -- Auto sell.
  optionsFrame:AddOptionButton({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoSell end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoSell(value)) end
  })

  -- Safe mode.
  optionsFrame:AddOptionButton({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return StateManager:GetCurrentState().safeMode end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetSafeMode(value)) end
  })

  -- Exclude equipment sets.
  if not Addon.IS_VANILLA then
    optionsFrame:AddOptionButton({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().excludeEquipmentSets end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeEquipmentSets(value)) end
    })
  end

  -- Exclude unbound equipment.
  optionsFrame:AddOptionButton({
    labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
    tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().excludeUnboundEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeUnboundEquipment(value)) end
  })

  -- Include poor items.
  optionsFrame:AddOptionButton({
    labelText = L.INCLUDE_POOR_ITEMS_TEXT,
    tooltipText = L.INCLUDE_POOR_ITEMS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includePoorItems end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludePoorItems(value)) end
  })

  -- Include below item level.
  optionsFrame:AddOptionButton({
    labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
    onUpdateTooltip = function(self, tooltip)
      local itemLevel = Colors.White(StateManager:GetCurrentState().includeBelowItemLevel.value)
      tooltip:SetText(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT)
      tooltip:AddLine(L.INCLUDE_BELOW_ITEM_LEVEL_TOOLTIP:format(itemLevel))
    end,
    get = function() return StateManager:GetCurrentState().includeBelowItemLevel.enabled end,
    set = function(value)
      if value then
        local currentState = StateManager:GetCurrentState()
        Popup:GetInteger({
          text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP,
          initialValue = currentState.includeBelowItemLevel.value,
          onAccept = function(self, value)
            StateManager:GetStore():Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = true, value = value }))
          end
        })
      else
        StateManager:GetStore():Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = value }))
      end
    end
  })

  -- Include unsuitable equipment.
  optionsFrame:AddOptionButton({
    labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
    tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includeUnsuitableEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeUnsuitableEquipment(value)) end
  })

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    optionsFrame:AddOptionButton({
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      tooltipText = L.INCLUDE_ARTIFACT_RELICS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().includeArtifactRelics end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeArtifactRelics(value)) end
    })
  end
end
