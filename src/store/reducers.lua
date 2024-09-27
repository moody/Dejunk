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
Reducers.globalReducer = Wux:CombineReducers({
  -- Chat messages.
  chatMessages = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.chatMessages)

    if action.type == "global/chatMessages/set" then
      state = action.payload
    end

    return state
  end,

  -- Item icons.
  itemIcons = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.itemIcons)

    if action.type == "global/itemIcons/set" then
      state = action.payload
    end

    return state
  end,

  -- Item tooltips.
  itemTooltips = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.itemTooltips)

    if action.type == "global/itemTooltips/set" then
      state = action.payload
    end

    return state
  end,

  -- Merchant button.
  merchantButton = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.merchantButton)

    if action.type == "global/merchantButton/set" then
      state = action.payload
    end

    return state
  end,

  -- Minimap icon.
  minimapIcon = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.minimapIcon)

    if action.type == "global/minimapIcon/patch" then
      state = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do state[k] = v end
    end

    return state
  end,

  -- Points.
  points = Wux:CombineReducers({
    -- Points -> MainWindow.
    mainWindow = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.mainWindow)

      if action.type == Actions.Types.Global.SET_MAIN_WINDOW_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_MAIN_WINDOW_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.mainWindow)
      end

      return state
    end,
    -- Points -> JunkFrame.
    junkFrame = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.junkFrame)

      if action.type == Actions.Types.Global.SET_JUNK_FRAME_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_JUNK_FRAME_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.junkFrame)
      end

      return state
    end,
    -- Points -> TransportFrame.
    transportFrame = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.transportFrame)

      if action.type == Actions.Types.Global.SET_TRANSPORT_FRAME_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_TRANSPORT_FRAME_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.transportFrame)
      end

      return state
    end,
    -- Points -> MerchantButton.
    merchantButton = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.merchantButton)

      if action.type == Actions.Types.Global.SET_MERCHANT_BUTTON_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_MERCHANT_BUTTON_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.merchantButton)
      end

      return state
    end,
  }),

  -- Auto junk frame.
  autoJunkFrame = ReducerFactories.autoJunkFrame(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Auto repair.
  autoRepair = ReducerFactories.autoRepair(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Auto sell.
  autoSell = ReducerFactories.autoSell(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Safe mode.
  safeMode = ReducerFactories.safeMode(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Exclude equipment sets.
  excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Exclude unbound equipment.
  excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Exclude warband equipment.
  excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Include below item level.
  includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Include by quality.
  includeByQuality = ReducerFactories.includeByQuality(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Include unsuitable equipment.
  includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Include artifact relics.
  includeArtifactRelics = ReducerFactories.includeArtifactRelics(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Inclusions.
  inclusions = ReducerFactories.inclusions(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Exclusions.
  exclusions = ReducerFactories.exclusions(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Item quality check boxes.
  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(GLOBAL_DEFAULT_STATE, Actions.Types.Global)
})

-- ============================================================================
-- Per Character Saved Variables Reducer
-- ============================================================================

--- @type WuxReducer<PercharState>
Reducers.percharReducer = Wux:CombineReducers({
  -- Character specific settings.
  characterSpecificSettings = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.characterSpecificSettings)

    if action.type == "perchar/characterSpecificSettings/toggle" then
      state = not state
    end

    return state
  end,

  -- Auto junk frame.
  autoJunkFrame = ReducerFactories.autoJunkFrame(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Auto repair.
  autoRepair = ReducerFactories.autoRepair(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Auto sell.
  autoSell = ReducerFactories.autoSell(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Safe mode.
  safeMode = ReducerFactories.safeMode(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Exclude equipment sets.
  excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Exclude unbound equipment.
  excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Exclude warband equipment.
  excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Include below item level.
  includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Include by quality.
  includeByQuality = ReducerFactories.includeByQuality(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Include unsuitable equipment.
  includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Include artifact relics.
  includeArtifactRelics = ReducerFactories.includeArtifactRelics(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Inclusions.
  inclusions = ReducerFactories.inclusions(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Exclusions.
  exclusions = ReducerFactories.exclusions(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Item quality check boxes.
  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar)
})

-- ============================================================================
-- Root Reducer
-- ============================================================================

--- @type WuxReducer<{global: GlobalState, perchar: PercharState}>
Reducers.rootReducer = Wux:CombineReducers({
  global = Reducers.globalReducer,
  perchar = Reducers.percharReducer
})
