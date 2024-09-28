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
  -- self:AddCharacterOptions(optionsFrame)
  self:AddGeneralOptions(optionsFrame)
  self:AddIncludeOptions(optionsFrame)
  self:AddExcludeOptions(optionsFrame)
  self:AddGlobalOptions(optionsFrame)
end

--- Adds character options to the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:AddCharacterOptions(optionsFrame)
  -- Character heading.
  optionsFrame:AddChild(Widgets:OptionHeading({ headingText = L.CHARACTER }))
end

--- Adds general options to the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:AddGeneralOptions(optionsFrame)
  -- General heading.
  optionsFrame:AddChild(Widgets:OptionHeading({ headingText = L.GENERAL }))

  -- Character specific settings.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return StateManager:GetPercharState().characterSpecificSettings end,
    set = function() StateManager:GetStore():Dispatch(Actions:ToggleCharacterSpecificSettings()) end
  }))

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
  if not Addon.IS_VANILLA then
    optionsFrame:AddChild(Widgets:OptionButton({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().excludeEquipmentSets end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeEquipmentSets(value)) end
    }))
  end

  do -- Exclude unbound equipment.
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetCurrentState().excludeUnboundEquipment end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeUnboundEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeUnboundEquipment.poor end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeUnboundEquipment.common end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeUnboundEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeUnboundEquipment.rare end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeUnboundEquipment.epic end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetCurrentState().excludeWarbandEquipment end,
      set = function(value) StateManager:Dispatch(Actions:SetExcludeWarbandEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeWarbandEquipment.poor end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeWarbandEquipment.common end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeWarbandEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeWarbandEquipment.rare end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.excludeWarbandEquipment.epic end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment({ epic = value })) end
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
      get = function() return StateManager:GetCurrentState().includeArtifactRelics end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeArtifactRelics(value)) end
    }))
  end

  -- Include below item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetCurrentState().includeBelowItemLevel.value
    end

    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      get = function() return StateManager:GetCurrentState().includeBelowItemLevel.enabled end,
      set = function(value) StateManager:Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = value })) end,
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
      local currentState = StateManager:GetCurrentState()
      Popup:GetInteger({
        text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP,
        initialValue = currentState.includeBelowItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(Actions:PatchIncludeBelowItemLevel({ value = value }))
        end
      })
    end)

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeBelowItemLevel.poor end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeBelowItemLevel.common end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeBelowItemLevel.uncommon end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeBelowItemLevel.rare end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeBelowItemLevel.epic end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include by quality.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      tooltipText = L.INCLUDE_BY_QUALITY_TOOLTIP .. "|n|n" .. Colors.Pink(L.OPTION_WARNING_BE_CAREFUL),
      get = function() return StateManager:GetCurrentState().includeByQuality end,
      set = function(value) StateManager:Dispatch(Actions:SetIncludeByQuality(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeByQuality.poor end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeByQuality({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeByQuality.common end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeByQuality({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeByQuality.uncommon end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeByQuality({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeByQuality.rare end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeByQuality({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeByQuality.epic end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeByQuality({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include unsuitable equipment.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetCurrentState().includeUnsuitableEquipment end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeUnsuitableEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeUnsuitableEquipment.poor end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeUnsuitableEquipment.common end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeUnsuitableEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeUnsuitableEquipment.rare end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetCurrentState().itemQualityCheckBoxes.includeUnsuitableEquipment.epic end,
        set = function(value) StateManager:Dispatch(Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end
end

--- Adds global options to the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:AddGlobalOptions(optionsFrame)
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
