local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")
local StateManager = Addon:GetModule("StateManager")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- MainWindowOptions - Profile
-- ============================================================================

--- Creates the panel of profile-scoped options.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateProfileOptionsPanel()
  local titleText = Colors.Blue(("%s (%s)"):format(L.OPTIONS_TEXT, Colors.White(L.PROFILE)))
  local panel, container = OptionsBuilder:CreatePanel({
    titleText = titleText,
    titleJustify = "LEFT",
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(titleText)
      tooltip:AddLine(L.PROFILE_OPTIONS_TOOLTIP:format(Colors.White(StateManager:GetProfileState().name)))
    end
  })

  local general = OptionsBuilder:AddGroup(container, L.GENERAL)

  -- Auto repair.
  general:AddOptionCard({
    labelText = L.AUTO_REPAIR_TEXT,
    descriptionText = L.AUTO_REPAIR_DESCRIPTION,
    get = function() return StateManager:GetProfileState().settings.autoRepair end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoRepair(value)) end
  })

  -- Auto sell.
  general:AddOptionCard({
    labelText = L.AUTO_SELL_TEXT,
    descriptionText = L.AUTO_SELL_DESCRIPTION,
    get = function() return StateManager:GetProfileState().settings.autoSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoSell(value)) end
  })

  local include = OptionsBuilder:AddGroup(container, L.INCLUDE)

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    include:AddOptionCard({
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      descriptionText = L.INCLUDE_ARTIFACT_RELICS_DESCRIPTION,
      get = function() return StateManager:GetProfileState().settings.includeArtifactRelics end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeArtifactRelics(value)) end
    })
  end

  -- Include by quality.
  do
    local function getState() return StateManager:GetProfileState().settings.includeByQuality end
    local mergeAction = ActionCreators.Profile.mergeIncludeByQuality

    local box = include:AddOptionCard({
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      descriptionText = L.INCLUDE_BY_QUALITY_DESCRIPTION,
      warningText = L.OPTION_WARNING_BE_CAREFUL,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include below item level.
  do
    local function getState() return StateManager:GetProfileState().settings.includeBelowItemLevel end
    local mergeAction = ActionCreators.Profile.mergeIncludeBelowItemLevel

    local box = include:AddOptionCard({
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      descriptionText = L.INCLUDE_BELOW_ITEM_LEVEL_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddItemLevelLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include below price.
  do
    local function getState() return StateManager:GetProfileState().settings.includeBelowPrice end
    local mergeAction = ActionCreators.Profile.mergeIncludeBelowPrice

    local box = include:AddOptionCard({
      labelText = L.INCLUDE_BELOW_PRICE_TEXT,
      descriptionText = L.INCLUDE_BELOW_PRICE_DESCRIPTION,
      warningText = L.OPTION_WARNING_BE_CAREFUL,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddPriceLine(getState, mergeAction)
    box:AddPriceScopeLine(getState, mergeAction, { "SELL", "BOTH" })
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include by equipment type.
  do
    local function getState() return StateManager:GetProfileState().settings.includeByEquipmentType end
    local mergeAction = ActionCreators.Profile.mergeIncludeByEquipmentType

    local box = include:AddOptionCard({
      labelText = L.INCLUDE_BY_EQUIPMENT_TYPE_TEXT,
      descriptionText = L.INCLUDE_BY_EQUIPMENT_TYPE_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddArmorLine(getState, mergeAction)
    box:AddWeaponsLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  local exclude = OptionsBuilder:AddGroup(container, L.EXCLUDE)

  -- Exclude above item level.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeAboveItemLevel end
    local mergeAction = ActionCreators.Profile.mergeExcludeAboveItemLevel

    local box = exclude:AddOptionCard({
      labelText = L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT,
      descriptionText = L.EXCLUDE_ABOVE_ITEM_LEVEL_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddItemLevelLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Exclude above price.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeAbovePrice end
    local mergeAction = ActionCreators.Profile.mergeExcludeAbovePrice

    local box = exclude:AddOptionCard({
      labelText = L.EXCLUDE_ABOVE_PRICE_TEXT,
      descriptionText = L.EXCLUDE_ABOVE_PRICE_DESCRIPTION,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddPriceLine(getState, mergeAction)
    box:AddPriceScopeLine(getState, mergeAction, { "DESTROY", "BOTH" })
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Exclude by equipment type.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeByEquipmentType end
    local mergeAction = ActionCreators.Profile.mergeExcludeByEquipmentType

    local box = exclude:AddOptionCard({
      labelText = L.EXCLUDE_BY_EQUIPMENT_TYPE_TEXT,
      descriptionText = L.EXCLUDE_BY_EQUIPMENT_TYPE_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddArmorLine(getState, mergeAction)
    box:AddWeaponsLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Exclude equipment sets.
  if not (Addon.IS_VANILLA or Addon.IS_TBC) then
    exclude:AddOptionCard({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      descriptionText = L.EXCLUDE_EQUIPMENT_SETS_DESCRIPTION,
      get = function() return StateManager:GetProfileState().settings.excludeEquipmentSets end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setExcludeEquipmentSets(value)) end
    })
  end

  -- Exclude unbound equipment.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeUnboundEquipment end
    local mergeAction = ActionCreators.Profile.mergeExcludeUnboundEquipment

    local box = exclude:AddOptionCard({
      labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
      descriptionText = L.EXCLUDE_UNBOUND_EQUIPMENT_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    local function getState() return StateManager:GetProfileState().settings.excludeWarbandEquipment end
    local mergeAction = ActionCreators.Profile.mergeExcludeWarbandEquipment

    local box = exclude:AddOptionCard({
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      descriptionText = L.EXCLUDE_WARBAND_EQUIPMENT_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  OptionsBuilder:AddSpecialEquipmentFootnote(panel)

  return panel
end
