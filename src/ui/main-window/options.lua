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

--- Initializes options for the given `optionsFrame`.
--- @param optionsFrame OptionsFrameWidget
function MainWindowOptions:Initialize(optionsFrame)
  -- Character.
  optionsFrame:AddChild(Widgets:OptionHeading({
    headingText = ("%s %s"):format(
      L.CHARACTER,
      Colors.Grey("(%s)"):format(
        Colors.White(UnitName("player"))
      )
    )
  }))
  self:AddIncludeOptions(optionsFrame)
  self:AddExcludeOptions(optionsFrame)

  -- Add frame for vertical spacing.
  local spacer = CreateFrame("Frame")
  spacer:SetWidth(1)
  spacer:SetHeight(Widgets:Padding())
  optionsFrame:AddChild(spacer)

  -- Global.
  self:AddGlobalOptions(optionsFrame)
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
      get = function() return StateManager:GetPercharState().excludeEquipmentSets end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setExcludeEquipmentSets(value)) end
    }))
  end

  do -- Exclude unbound equipment.
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetPercharState().excludeUnboundEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setExcludeUnboundEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeUnboundEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeUnboundEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeUnboundEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeUnboundEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeUnboundEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    local frame = Widgets:OptionButton({
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      tooltipText = L.EXCLUDE_WARBAND_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetPercharState().excludeWarbandEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setExcludeWarbandEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeWarbandEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeWarbandEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeWarbandEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeWarbandEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.excludeWarbandEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment({ epic = value })) end
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
      get = function() return StateManager:GetPercharState().includeArtifactRelics end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setIncludeArtifactRelics(value)) end
    }))
  end

  -- Include below item level.
  do
    local LABEL_TEXT_FORMAT = Colors.White(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. " " .. Colors.Grey("(%s)")

    local function getItemLevel()
      return StateManager:GetPercharState().includeBelowItemLevel.value
    end

    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      get = function() return StateManager:GetPercharState().includeBelowItemLevel.enabled end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.patchIncludeBelowItemLevel({ enabled = value })) end,
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
        initialValue = StateManager:GetPercharState().includeBelowItemLevel.value,
        onAccept = function(self, value)
          StateManager:Dispatch(ActionCreators.Perchar.patchIncludeBelowItemLevel({ value = value }))
        end
      })
    end)

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeBelowItemLevel.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeBelowItemLevel({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeBelowItemLevel.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeBelowItemLevel({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeBelowItemLevel.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeBelowItemLevel({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeBelowItemLevel.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeBelowItemLevel({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeBelowItemLevel.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeBelowItemLevel({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include by quality.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      tooltipText = L.INCLUDE_BY_QUALITY_TOOLTIP .. "|n|n" .. Colors.Pink(L.OPTION_WARNING_BE_CAREFUL),
      get = function() return StateManager:GetPercharState().includeByQuality end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setIncludeByQuality(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeByQuality.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeByQuality({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeByQuality.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeByQuality({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeByQuality.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeByQuality({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeByQuality.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeByQuality({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeByQuality.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeByQuality({ epic = value })) end
      }
    })

    optionsFrame:AddChild(frame)
  end

  do -- Include unsuitable equipment.
    local frame = Widgets:OptionButton({
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP .. "|n|n" .. Colors.Pink(L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT),
      get = function() return StateManager:GetPercharState().includeUnsuitableEquipment end,
      set = function(value) StateManager:Dispatch(ActionCreators.Perchar.setIncludeUnsuitableEquipment(value)) end
    })

    frame:InitializeItemQualityCheckBoxes({
      poor = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeUnsuitableEquipment.poor end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment({ poor = value })) end
      },
      common = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeUnsuitableEquipment.common end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment({ common = value })) end
      },
      uncommon = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeUnsuitableEquipment.uncommon end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment({ uncommon = value })) end
      },
      rare = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeUnsuitableEquipment.rare end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment({ rare = value })) end
      },
      epic = {
        get = function() return StateManager:GetPercharState().itemQualityCheckBoxes.includeUnsuitableEquipment.epic end,
        set = function(value) StateManager:Dispatch(ActionCreators.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment({ epic = value })) end
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

  -- Auto junk frame.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoJunkFrame end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoJunkFrame(value)) end
  }))

  -- Auto repair.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoRepair end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoRepair(value)) end
  }))

  -- Auto sell.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return StateManager:GetGlobalState().autoSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setAutoSell(value)) end
  }))

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

  -- Safe mode.
  optionsFrame:AddChild(Widgets:OptionButton({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return StateManager:GetGlobalState().safeMode end,
    set = function(value) StateManager:Dispatch(ActionCreators.Global.setSafeMode(value)) end
  }))
end
