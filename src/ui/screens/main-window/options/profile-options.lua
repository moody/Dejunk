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

  -- Auto repair.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.AUTO_REPAIR_TEXT,
    descriptionText = L.AUTO_REPAIR_DESCRIPTION,
    get = function() return StateManager:GetProfileState().settings.autoRepair end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoRepair(value)) end
  })

  -- Auto sell.
  OptionsBuilder:AddOptionCard(container, {
    labelText = L.AUTO_SELL_TEXT,
    descriptionText = L.AUTO_SELL_DESCRIPTION,
    get = function() return StateManager:GetProfileState().settings.autoSell end,
    set = function(value) StateManager:Dispatch(ActionCreators.Profile.setAutoSell(value)) end
  })

  -- Include by quality.
  do
    local function getState() return StateManager:GetProfileState().settings.includeByQuality end
    local mergeAction = ActionCreators.Profile.mergeIncludeByQuality

    local box = OptionsBuilder:AddOptionCard(container, {
      labelText = L.INCLUDE_BY_QUALITY_TEXT,
      descriptionText = L.INCLUDE_BY_QUALITY_DESCRIPTION,
      warningText = L.OPTION_WARNING_BE_CAREFUL,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Exclude above item level.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeAboveItemLevel end
    local mergeAction = ActionCreators.Profile.mergeExcludeAboveItemLevel

    local box = OptionsBuilder:AddOptionCard(container, {
      labelText = L.EXCLUDE_ABOVE_ITEM_LEVEL_TEXT,
      descriptionText = L.EXCLUDE_ABOVE_ITEM_LEVEL_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddItemLevelLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include below item level.
  do
    local function getState() return StateManager:GetProfileState().settings.includeBelowItemLevel end
    local mergeAction = ActionCreators.Profile.mergeIncludeBelowItemLevel

    local box = OptionsBuilder:AddOptionCard(container, {
      labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
      descriptionText = L.INCLUDE_BELOW_ITEM_LEVEL_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddItemLevelLine(getState, mergeAction)
    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include unsuitable equipment.
  do
    local function getState() return StateManager:GetProfileState().settings.includeUnsuitableEquipment end
    local mergeAction = ActionCreators.Profile.mergeIncludeUnsuitableEquipment

    local box = OptionsBuilder:AddOptionCard(container, {
      labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
      descriptionText = L.INCLUDE_UNSUITABLE_EQUIPMENT_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include by equipment type.
  do
    local function getState() return StateManager:GetProfileState().settings.includeByEquipmentType end
    local mergeAction = ActionCreators.Profile.mergeIncludeByEquipmentType

    local box = OptionsBuilder:AddOptionCard(container, {
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

  -- Exclude by equipment type.
  do
    local function getState() return StateManager:GetProfileState().settings.excludeByEquipmentType end
    local mergeAction = ActionCreators.Profile.mergeExcludeByEquipmentType

    local box = OptionsBuilder:AddOptionCard(container, {
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
    OptionsBuilder:AddOptionCard(container, {
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

    local box = OptionsBuilder:AddOptionCard(container, {
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

    local box = OptionsBuilder:AddOptionCard(container, {
      labelText = L.EXCLUDE_WARBAND_EQUIPMENT_TEXT,
      descriptionText = L.EXCLUDE_WARBAND_EQUIPMENT_DESCRIPTION,
      ignoresSpecialEquipment = true,
      get = function() return getState().enabled end,
      set = function(value) StateManager:Dispatch(mergeAction({ enabled = value })) end
    }):AddSettingsBox()

    box:AddQualitiesLine(getState, mergeAction)
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    OptionsBuilder:AddOptionCard(container, {
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      descriptionText = L.INCLUDE_ARTIFACT_RELICS_DESCRIPTION,
      get = function() return StateManager:GetProfileState().settings.includeArtifactRelics end,
      set = function(value) StateManager:Dispatch(ActionCreators.Profile.setIncludeArtifactRelics(value)) end
    })
  end

  OptionsBuilder:AddSpecialEquipmentFootnote(panel)

  return panel
end
