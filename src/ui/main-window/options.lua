local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

--- Initializes options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:Initialize(optionsFrame)
  -- ============================================================================
  -- Per Character
  -- ============================================================================

  -- Character heading.
  -- optionsFrame:AddChild(Widgets:OptionHeading({ headingText = L.CHARACTER }))

  -- Character specific settings.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return StateManager:GetPercharState().characterSpecificSettings end,
    set = function() StateManager:GetStore():Dispatch(Actions:ToggleCharacterSpecificSettings()) end
  }))

  -- ============================================================================
  -- General
  -- ============================================================================

  -- General heading.
  optionsFrame:AddChild(Widgets:OptionHeading({ headingText = L.GENERAL }))

  -- Auto junk frame.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoJunkFrame end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoJunkFrame(value)) end
  }))

  -- Auto repair.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoRepair end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoRepair(value)) end
  }))

  -- Auto sell.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoSell end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoSell(value)) end
  }))

  -- Safe mode.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return StateManager:GetCurrentState().safeMode end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetSafeMode(value)) end
  }))

  -- Exclude heading.
  optionsFrame:AddChild(Widgets:OptionHeading({
    headingText = L.EXCLUDE,
    headingTemplate = "GameFontNormalSmall",
    headingColor = Colors.Green,
    headingJustify = "CENTER"
  }))

  -- Exclude equipment sets.
  if not Addon.IS_VANILLA then
    optionsFrame:AddChild(Widgets:OptionButton({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().excludeEquipmentSets end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeEquipmentSets(value)) end
    }))
  end

  -- Exclude unbound equipment.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
    tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().excludeUnboundEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeUnboundEquipment(value)) end
  }))

  -- Include heading.
  optionsFrame:AddChild(Widgets:OptionHeading({
    headingText = L.INCLUDE,
    headingTemplate = "GameFontNormalSmall",
    headingColor = Colors.Red,
    headingJustify = "CENTER"
  }))

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    optionsFrame:AddChild(Widgets:OptionButton({
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      tooltipText = L.INCLUDE_ARTIFACT_RELICS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().includeArtifactRelics end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeArtifactRelics(value)) end
    }))
  end

  -- Include below item level.
  do
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      get = function() return StateManager:GetCurrentState().includeBelowItemLevel.enabled end,
      set = function(value) StateManager:Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = value })) end,
      enableClickHandling = true,
      onUpdateTooltip = function(self, tooltip)
        local itemLevel = Colors.White(StateManager:GetCurrentState().includeBelowItemLevel.value)
        tooltip:SetText(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT)
        tooltip:AddLine(L.INCLUDE_BELOW_ITEM_LEVEL_TOOLTIP:format(itemLevel))
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.CHANGE_VALUE)
      end,
    })

    frame:SetClickHandler("RightButton", "NONE", function()
      local currentState = StateManager:GetCurrentState()
      Popup:GetInteger({
        text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP,
        initialValue = currentState.includeBelowItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(Actions:PatchIncludeBelowItemLevel({ value = value }))
        end
      })
    end)

    optionsFrame:AddChild(frame)
  end

  -- Include poor items.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.INCLUDE_POOR_ITEMS_TEXT,
    tooltipText = L.INCLUDE_POOR_ITEMS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includePoorItems end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludePoorItems(value)) end
  }))

  -- Include unsuitable equipment.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
    tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includeUnsuitableEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeUnsuitableEquipment(value)) end
  }))

  -- ============================================================================
  -- Global
  -- ============================================================================

  -- Global heading.
  optionsFrame:AddChild(Widgets:OptionHeading({ headingText = L.GLOBAL }))

  -- Bag item icons.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_ICONS_TEXT,
    tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemIcons end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemIcons(value)) end
  }))

  -- Bag item tooltips.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemTooltips end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemTooltips(value)) end
  }))

  -- Chat messages.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetGlobalState().chatMessages end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetChatMessages(value)) end
  }))

  -- Merchant button.
  do
    local frame = Widgets:OptionButton({
      labelText = L.MERCHANT_BUTTON_TEXT,
      get = function() return StateManager:GetGlobalState().merchantButton end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetMerchantButton(value)) end,
      enableClickHandling = true,
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetText(L.MERCHANT_BUTTON_TEXT)
        tooltip:AddLine(L.MERCHANT_BUTTON_TOOLTIP)
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.RESET_POSITION)
      end
    })

    frame:SetClickHandler("RightButton", "NONE", function()
      StateManager:Dispatch(Actions:ResetMerchantButtonPoint())
    end)

    optionsFrame:AddChild(frame)
  end

  -- Minimap icon.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.MINIMAP_ICON_TEXT,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end
  }))
end
