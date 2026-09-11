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

--- Initializes global-scoped options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:InitializeGlobalOptions(optionsFrame)
  -- Bag item icons.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_ICONS_TEXT,
    tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemIcons end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemIcons(value)) end
  }))

  -- Bag item tooltips.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetGlobalState().itemTooltips end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setItemTooltips(value)) end
  }))

  -- Chat messages.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetGlobalState().chatMessages end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setChatMessages(value)) end
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
end

--- Initializes profile-scoped options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:InitializeProfileOptions(optionsFrame)
  -- Auto junk frame.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetProfileState().settings.autoJunkFrame end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoJunkFrame(value)) end
  }))

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

  -- Safe mode.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return StateManager:GetProfileState().settings.safeMode end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setSafeMode(value)) end
  }))

  self:AddIncludeOptions(optionsFrame)
  self:AddExcludeOptions(optionsFrame)
end

--- Adds exclude options to the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:AddExcludeOptions(optionsFrame)
  -- Exclude heading.
  optionsFrame:AddChild(Widgets:OptionHeading({
    headingText = L.EXCLUDE,
    headingTemplate = "GameFontNormalSmall",
    headingColor = Colors.Green,
    headingJustify = "CENTER"
  }))

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
      get = function() return StateManager:GetProfileState().settings.excludeUnboundEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setExcludeUnboundEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeUnboundEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeUnboundEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeUnboundEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeUnboundEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeUnboundEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeUnboundEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeUnboundEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeUnboundEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeUnboundEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeUnboundEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.excludeWarbandEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setExcludeWarbandEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeWarbandEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeWarbandEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeWarbandEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeWarbandEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeWarbandEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeWarbandEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeWarbandEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeWarbandEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.excludeWarbandEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.excludeWarbandEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end
end

--- Adds include options to the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:AddIncludeOptions(optionsFrame)
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
      get = function() return StateManager:GetProfileState().settings.includeArtifactRelics end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeArtifactRelics(value)) end
    }))
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
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.patchIncludeBelowItemLevel({ enabled = value })) end,
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
        text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP,
        initialValue = StateManager:GetProfileState().settings.includeBelowItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(ActionCreators.Profile.patchIncludeBelowItemLevel({ value = value }))
        end
      })
    end)

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeBelowItemLevel.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeBelowItemLevel({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeBelowItemLevel.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeBelowItemLevel({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeBelowItemLevel.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeBelowItemLevel({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeBelowItemLevel.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeBelowItemLevel({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeBelowItemLevel.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeBelowItemLevel({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include by quality.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      tooltipText = L.INCLUDE_BY_QUALITY_TOOLTIP .. "|n|n" .. Colors.Pink(L.OPTION_WARNING_BE_CAREFUL),
      get = function() return StateManager:GetProfileState().settings.includeByQuality end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeByQuality(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeByQuality.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeByQuality({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeByQuality.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeByQuality({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeByQuality.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeByQuality({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeByQuality.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeByQuality({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeByQuality.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeByQuality({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include unsuitable equipment.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetProfileState().settings.includeUnsuitableEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeUnsuitableEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeUnsuitableEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeUnsuitableEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeUnsuitableEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeUnsuitableEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeUnsuitableEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeUnsuitableEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeUnsuitableEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeUnsuitableEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetProfileState().settings.itemQualityCheckBoxes.includeUnsuitableEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Profile.itemQualityCheckBoxes.includeUnsuitableEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end
end
