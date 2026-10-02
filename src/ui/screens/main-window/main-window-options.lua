local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
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

--- Creates a titled, scrollable options panel.
--- @param options TitledPanelComponentOptions
--- @return TitledPanelComponent panel
--- @return WaffleFlexComponent content Component the panel's rows are added to.
local function createOptionsPanel(options)
  local panel = ComponentFactory:TitledPanel(options)
  local scrollPanel = panel.Content:AttachComponent(ComponentFactory:ScrollPanel())
  scrollPanel.ScrollChild:SetGap(Widgets:Padding())
  return panel, scrollPanel.ScrollChild
end

--- Adds an option row to `container`, built by `createFrame` once it is
--- first laid out.
--- @param container WaffleFlexComponent
--- @param createFrame fun(parent: Frame): OptionButtonWidget
local function addOption(container, createFrame)
  container:AddChild({
    height = "AUTO",
    frameFactory = createFrame,

    --- @param frame OptionButtonWidget
    --- @param width number
    onMeasure = function(frame, width)
      return width, frame:GetHeight()
    end
  })
end

-- ============================================================================
-- MainWindowOptions - Global
-- ============================================================================

--- Creates the panel of global-scoped options.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateGlobalOptionsPanel()
  local titleText = Colors.Blue(("%s (%s)"):format(L.OPTIONS_TEXT, Colors.White(L.GLOBAL)))
  local panel, container = createOptionsPanel({
    titleText = titleText,
    titleJustify = "LEFT",
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(titleText)
      tooltip:AddLine(L.GLOBAL_OPTIONS_TOOLTIP)
    end
  })

  -- Safe destroy.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.SAFE_DESTROY_TEXT,
      tooltipText = L.SAFE_DESTROY_TOOLTIP,
      get = function() return StateManager:GetGlobalState().safeDestroy end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeDestroy(value)) end
    })
  end)

  -- Safe sell.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.SAFE_SELL_TEXT,
      tooltipText = L.SAFE_SELL_TOOLTIP,
      get = function() return StateManager:GetGlobalState().safeSell end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeSell(value)) end
    })
  end)

  -- Merchant button.
  addOption(container, function(parent)
    local frame = Widgets:OptionButton({
      parent = parent,
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

    return frame
  end)

  -- Minimap icon.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.MINIMAP_ICON_TEXT,
      tooltipText = L.MINIMAP_ICON_TOOLTIP,
      get = function() return MinimapIcon:IsEnabled() end,
      set = function(value) MinimapIcon:SetEnabled(value) end
    })
  end)

  -- Auto junk frame.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.AUTO_JUNK_FRAME_TEXT,
      tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
      get = function() return StateManager:GetGlobalState().autoJunkFrame end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoJunkFrame(value)) end
    })
  end)

  -- Auto lootable frame.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.AUTO_LOOTABLE_FRAME_TEXT,
      tooltipText = L.AUTO_LOOTABLE_FRAME_TOOLTIP,
      get = function() return StateManager:GetGlobalState().autoLootableFrame end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoLootableFrame(value)) end
    })
  end)

  -- Chat messages.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.CHAT_MESSAGES_TEXT,
      tooltipText = L.CHAT_MESSAGES_TOOLTIP,
      get = function() return StateManager:GetGlobalState().chatMessages end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setChatMessages(value)) end
    })
  end)

  -- Bag item tooltips.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
      tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
      get = function() return StateManager:GetGlobalState().itemTooltips end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemTooltips(value)) end
    })
  end)

  -- Bag item icons.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.BAG_ITEM_ICONS_TEXT,
      tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
      get = function() return StateManager:GetGlobalState().itemIcons end,
      set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemIcons(value)) end
    })
  end)

  return panel
end

-- ============================================================================
-- MainWindowOptions - Profile
-- ============================================================================

--- Creates the panel of profile-scoped options.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateProfileOptionsPanel()
  local titleText = Colors.Blue(("%s (%s)"):format(L.OPTIONS_TEXT, Colors.White(L.PROFILE)))
  local panel, container = createOptionsPanel({
    titleText = titleText,
    titleJustify = "LEFT",
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(titleText)
      tooltip:AddLine(L.PROFILE_OPTIONS_TOOLTIP:format(Colors.White(StateManager:GetProfileState().name)))
    end
  })

  -- Auto repair.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.AUTO_REPAIR_TEXT,
      tooltipText = L.AUTO_REPAIR_TOOLTIP,
      get = function() return StateManager:GetProfileState().settings.autoRepair end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoRepair(value)) end
    })
  end)

  -- Auto sell.
  addOption(container, function(parent)
    return Widgets:OptionButton({
      parent = parent,
      labelText = L.AUTO_SELL_TEXT,
      tooltipText = L.AUTO_SELL_TOOLTIP,
      get = function() return StateManager:GetProfileState().settings.autoSell end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoSell(value)) end
    })
  end)

  -- Include by quality.
  addOption(container, function(parent)
    local frame = Widgets:OptionButton({
      parent = parent,
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      tooltipText = L.INCLUDE_BY_QUALITY_TOOLTIP .. "|n|n" .. Colors.Pink(L.OPTION_WARNING_BE_CAREFUL),
      get = function() return StateManager:GetProfileState().settings.includeByQuality.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeIncludeByQuality({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.includeByQuality.qualities end,
      ActionCreators.Profile.mergeIncludeByQuality
    ))

    return frame
  end)

  -- Exclude above item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetProfileState().settings.excludeAboveItemLevel.value
    end

    addOption(container, function(parent)
      local frame = Widgets:OptionButton({
        parent = parent,
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

      return frame
    end)
  end

  -- Include below item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetProfileState().settings.includeBelowItemLevel.value
    end

    addOption(container, function(parent)
      local frame = Widgets:OptionButton({
        parent = parent,
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

      return frame
    end)
  end

  -- Include unsuitable equipment.
  addOption(container, function(parent)
    local frame = Widgets:OptionButton({
      parent = parent,
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.includeUnsuitableEquipment.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeIncludeUnsuitableEquipment({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.includeUnsuitableEquipment.qualities end,
      ActionCreators.Profile.mergeIncludeUnsuitableEquipment
    ))

    return frame
  end)

  -- Exclude equipment sets.
  if not (Addon.IS_VANILLA or Addon.IS_TBC) then
    addOption(container, function(parent)
      return Widgets:OptionButton({
        parent = parent,
        labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
        tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
        get = function() return StateManager:GetProfileState().settings.excludeEquipmentSets end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.setExcludeEquipmentSets(value)) end
      })
    end)
  end

  -- Exclude unbound equipment.
  addOption(container, function(parent)
    local frame = Widgets:OptionButton({
      parent = parent,
      labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.excludeUnboundEquipment.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeExcludeUnboundEquipment({ enabled = value })) end
    })

    frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
      function() return StateManager:GetProfileState().settings.excludeUnboundEquipment.qualities end,
      ActionCreators.Profile.mergeExcludeUnboundEquipment
    ))

    return frame
  end)

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    addOption(container, function(parent)
      local frame = Widgets:OptionButton({
        parent = parent,
        labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
        tooltipText = L.EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
        get = function() return StateManager:GetProfileState().settings.excludeWarbandEquipment.enabled end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.mergeExcludeWarbandEquipment({ enabled = value })) end
      })

      frame:InitializeItemQualityCheckBoxes(buildItemQualityCheckBoxesOptions(
        function() return StateManager:GetProfileState().settings.excludeWarbandEquipment.qualities end,
        ActionCreators.Profile.mergeExcludeWarbandEquipment
      ))

      return frame
    end)
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    addOption(container, function(parent)
      return Widgets:OptionButton({
        parent = parent,
        labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
        tooltipText = L.INCLUDE_ARTIFACT_RELICS_TOOLTIP,
        get = function() return StateManager:GetProfileState().settings.includeArtifactRelics end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeArtifactRelics(value)) end
      })
    end)
  end

  return panel
end
