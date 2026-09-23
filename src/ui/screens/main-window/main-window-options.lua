local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- Local Functions
-- ============================================================================

local QUALITIES = { "poor", "common", "uncommon", "rare", "epic" }

--- Builds options for `OptionButton:InitializeItemQualityCheckBoxes()`.
--- @param getQualities fun(): ItemQualitiesState
--- @param mergeAction fun(t: table): WuxPayloadAction
--- @return OptionButtonItemQualityCheckBoxesOptions
local function buildItemQualityCheckBoxesOptions(getQualities, mergeAction)
  local options = {}
  for _, quality in ipairs(QUALITIES) do
    options[quality] = {
      get = function() return getQualities()[quality] end,
      set = function(value) StateManager:Dispatch(mergeAction({ qualities = { [quality] = value } })) end
    }
  end
  return options
end

-- ============================================================================
-- MainWindowOptions - Global
-- ============================================================================

--- Initializes global-scoped options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:InitializeGlobalOptions(optionsFrame)
  -- Safe destroy.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.SAFE_DESTROY_TEXT,
    tooltipText = L.SAFE_DESTROY_TOOLTIP,
    get = function() return StateManager:GetGlobalState().safeDestroy end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeDestroy(value)) end
  }))

  -- Safe sell.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.SAFE_SELL_TEXT,
    tooltipText = L.SAFE_SELL_TOOLTIP,
    get = function() return StateManager:GetGlobalState().safeSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeSell(value)) end
  }))

  -- Merchant button.
  do
    local frame = Widgets:OptionButton({
      labelText = L.MERCHANT_BUTTON_TEXT,
      get = function() return StateManager:GetGlobalState().merchantButton end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setMerchantButton(value)) end,
      enableClickHandling = true,
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetText(L.MERCHANT_BUTTON_TEXT)
        tooltip:AddLine(L.MERCHANT_BUTTON_TOOLTIP)
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.RESET_POSITION)
      end
    })

    frame:SetClickHandler("RightButton", "NONE", function()
      StateManager:Dispatch(ActionCreators.Global.points.merchantButton.reset())
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

  -- Auto junk frame.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoJunkFrame end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoJunkFrame(value)) end
  }))

  -- Chat messages.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetGlobalState().chatMessages end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setChatMessages(value)) end
  }))

  -- Bag item tooltips.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemTooltips end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemTooltips(value)) end
  }))

  -- Bag item icons.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_ICONS_TEXT,
    tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemIcons end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemIcons(value)) end
  }))
end

-- ============================================================================
-- MainWindowOptions - Profile
-- ============================================================================

--- Initializes profile-scoped options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:InitializeProfileOptions(optionsFrame)
  -- Auto repair.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return StateManager:GetProfileState().settings.autoRepair end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoRepair(value)) end
  }))

  -- Auto sell.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return StateManager:GetProfileState().settings.autoSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoSell(value)) end
  }))

  do -- Include by quality.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      tooltipText = L.INCLUDE_BY_QUALITY_TOOLTIP .. "|n|n" .. Colors.Pink(L.OPTION_WARNING_BE_CAREFUL),
      get = function() return StateManager:GetProfileState().settings.includeByQuality.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeIncludeByQuality({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.includeByQuality.qualities end,
      ActionCreators.Profile.mergeIncludeByQuality
    ))

    optionsFrame:AddChild(frame)
  end

  -- Exclude above item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetProfileState().settings.excludeAboveItemLevel.value
    end

    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT,
      get = function() return StateManager:GetProfileState().settings.excludeAboveItemLevel.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeExcludeAboveItemLevel({ enabled = value })) end,
      enableClickHandling = true,
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetText(L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT)
        tooltip:AddLine(L.EXCLUDE_ABOVE_ITEM_LEVEL_TOOLTIP:format(Colors.White(getItemLevel())))
        tooltip:AddLine(" ")
        tooltip:AddLine(Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT))
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.CHANGE_VALUE)
      end,
    })

    frame:HookScript("OnUpdate", function()
      frame.label:SetText(LABEL_TEXT_FORMAT:format(Colors.Yellow(getItemLevel())))
    end)

    frame:SetClickHandler("RightButton", "NONE", function()
      Popup:GetInteger({
        text = Colors.Gold(L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT) .. "|n|n" .. L.ITEM_LEVEL_OPTION_POPUP_HELP,
        initialValue = StateManager:GetProfileState().settings.excludeAboveItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(ActionCreators.Profile.mergeExcludeAboveItemLevel({ value = value }))
        end
      })
    end)

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.excludeAboveItemLevel.qualities end,
      ActionCreators.Profile.mergeExcludeAboveItemLevel
    ))

    optionsFrame:AddChild(frame)
  end

  -- Include below item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetProfileState().settings.includeBelowItemLevel.value
    end

    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      get = function() return StateManager:GetProfileState().settings.includeBelowItemLevel.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeIncludeBelowItemLevel({ enabled = value })) end,
      enableClickHandling = true,
      onUpdateTooltip = function(self, tooltip)
        tooltip:SetText(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT)
        tooltip:AddLine(L.INCLUDE_BELOW_ITEM_LEVEL_TOOLTIP:format(Colors.White(getItemLevel())))
        tooltip:AddLine(" ")
        tooltip:AddLine(Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT))
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L.RIGHT_CLICK, L.CHANGE_VALUE)
      end,
    })

    frame:HookScript("OnUpdate", function()
      frame.label:SetText(LABEL_TEXT_FORMAT:format(Colors.Yellow(getItemLevel())))
    end)

    frame:SetClickHandler("RightButton", "NONE", function()
      Popup:GetInteger({
        text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.ITEM_LEVEL_OPTION_POPUP_HELP,
        initialValue = StateManager:GetProfileState().settings.includeBelowItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(ActionCreators.Profile.mergeIncludeBelowItemLevel({ value = value }))
        end
      })
    end)

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.includeBelowItemLevel.qualities end,
      ActionCreators.Profile.mergeIncludeBelowItemLevel
    ))

    optionsFrame:AddChild(frame)
  end

  do -- Include unsuitable equipment.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.includeUnsuitableEquipment.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeIncludeUnsuitableEquipment({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.includeUnsuitableEquipment.qualities end,
      ActionCreators.Profile.mergeIncludeUnsuitableEquipment
    ))

    optionsFrame:AddChild(frame)
  end

  -- Exclude equipment sets.
  if not (Addon.IS_VANILLA or Addon.IS_TBC) then
    optionsFrame:AddChild(Widgets:OptionButton({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
      get = function() return StateManager:GetProfileState().settings.excludeEquipmentSets end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setExcludeEquipmentSets(value)) end
    }))
  end

  do -- Exclude unbound equipment.
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.excludeUnboundEquipment.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeExcludeUnboundEquipment({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.excludeUnboundEquipment.qualities end,
      ActionCreators.Profile.mergeExcludeUnboundEquipment
    ))

    optionsFrame:AddChild(frame)
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.excludeWarbandEquipment.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeExcludeWarbandEquipment({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.excludeWarbandEquipment.qualities end,
      ActionCreators.Profile.mergeExcludeWarbandEquipment
    ))

    optionsFrame:AddChild(frame)
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    optionsFrame:AddChild(Widgets:OptionButton({
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      tooltipText = L.INCLUDE_ARTIFACT_RELICS_TOOLTIP,
      get = function() return StateManager:GetProfileState().settings.includeArtifactRelics end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeArtifactRelics(value)) end
    }))
  end
end
