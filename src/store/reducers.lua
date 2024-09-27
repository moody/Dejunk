local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local ReducerFactories = Addon:GetModule("ReducerFactories")
local Wux = Addon.Wux

--- @class Reducers
local Reducers = Addon:GetModule("Reducers")

-- ============================================================================
-- Default States
-- ============================================================================

--- Default state.
--- @class DefaultState
local DEFAULT_STATE = {
  autoJunkFrame = false,
  autoRepair = false,
  autoSell = false,
  safeMode = false,

  excludeEquipmentSets = true,
  excludeUnboundEquipment = false,
  excludeWarbandEquipment = false,

  includeBelowItemLevel = { enabled = false, value = 0 },
  includeByQuality = true,
  includeUnsuitableEquipment = false,
  includeArtifactRelics = false,

  inclusions = { --[[ ["itemId"] = true, ... ]] },
  exclusions = { --[[ ["itemId"] = true, ... ]] },

  itemQualityCheckBoxes = {
    excludeUnboundEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    excludeWarbandEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    includeByQuality = { poor = true, common = false, uncommon = false, rare = false, epic = false },
  }
}

--- Global default state.
--- @class GlobalState : DefaultState
local GLOBAL_DEFAULT_STATE = Wux:DeepCopy(DEFAULT_STATE)
GLOBAL_DEFAULT_STATE.chatMessages = true
GLOBAL_DEFAULT_STATE.itemIcons = false
GLOBAL_DEFAULT_STATE.itemTooltips = true
GLOBAL_DEFAULT_STATE.merchantButton = true
GLOBAL_DEFAULT_STATE.minimapIcon = { hide = false }
GLOBAL_DEFAULT_STATE.points = {
  mainWindow = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  junkFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  transportFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  merchantButton = { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = 75, offsetY = -145 }
}

-- Per character default state.
--- @class PercharState : DefaultState
local PERCHAR_DEFAULT_STATE = Wux:DeepCopy(DEFAULT_STATE)
PERCHAR_DEFAULT_STATE.characterSpecificSettings = false

-- ============================================================================
-- Global Saved Variables Reducer
-- ============================================================================

--- @type WuxReducer<GlobalState>
local globalReducer = Wux:CombineReducers({
  chatMessages = ReducerFactories.chatMessages(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  itemIcons = ReducerFactories.itemIcons(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  itemTooltips = ReducerFactories.itemTooltips(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  merchantButton = ReducerFactories.merchantButton(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  minimapIcon = ReducerFactories.minimapIcon(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  points = ReducerFactories.points(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  autoJunkFrame = ReducerFactories.autoJunkFrame(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  autoRepair = ReducerFactories.autoRepair(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  autoSell = ReducerFactories.autoSell(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  safeMode = ReducerFactories.safeMode(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  includeArtifactRelics = ReducerFactories.includeArtifactRelics(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  includeByQuality = ReducerFactories.includeByQuality(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  inclusions = ReducerFactories.inclusions(GLOBAL_DEFAULT_STATE, Actions.Types.Global),
  exclusions = ReducerFactories.exclusions(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(GLOBAL_DEFAULT_STATE, Actions.Types.Global)
})

-- ============================================================================
-- Per Character Saved Variables Reducer
-- ============================================================================

--- @type WuxReducer<PercharState>
local percharReducer = Wux:CombineReducers({
  characterSpecificSettings = ReducerFactories.characterSpecificSettings(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  autoJunkFrame = ReducerFactories.autoJunkFrame(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  autoRepair = ReducerFactories.autoRepair(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  autoSell = ReducerFactories.autoSell(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  safeMode = ReducerFactories.safeMode(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  includeArtifactRelics = ReducerFactories.includeArtifactRelics(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  includeByQuality = ReducerFactories.includeByQuality(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  inclusions = ReducerFactories.inclusions(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),
  exclusions = ReducerFactories.exclusions(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar)
})

-- ============================================================================
-- Root Reducer
-- ============================================================================

--- @type WuxReducer<{global: GlobalState, perchar: PercharState}>
Reducers.rootReducer = Wux:CombineReducers({
  global = globalReducer,
  perchar = percharReducer
})
