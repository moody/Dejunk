local _, Addon = ...
local Reducers = Addon:GetModule("Reducers") --- @class Reducers
local Wux = Addon.Wux --- @type Wux

-- ============================================================================
-- Default States
-- ============================================================================

--- Default state.
--- @class DefaultState
local DEFAULT_STATE = {
  -- User interface.
  chatMessages = true,
  itemTooltips = true,
  merchantButton = true,
  minimapIcon = { hide = false },

  -- Junk.
  autoJunkFrame = false,
  autoSell = false,
  autoRepair = false,
  safeMode = false,

  excludeEquipmentSets = not Addon.IS_VANILLA,
  excludeUnboundEquipment = Addon.IS_RETAIL,

  includePoorItems = true,
  includeBelowItemLevel = { enabled = false, value = 0 },
  includeUnsuitableEquipment = false,
  includeArtifactRelics = false,

  inclusions = { --[[ ["itemId"] = true, ... ]] },
  exclusions = { --[[ ["itemId"] = true, ... ]] },
}

--- Global default state.
--- @class GlobalState : DefaultState
local GLOBAL_DEFAULT_STATE = Wux:DeepCopy(DEFAULT_STATE)

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

  -- TODO: add more reducers.
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

  -- Chat messages.
  chatMessages = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.chatMessages)

    if action.type == "perchar/chatMessages/set" then
      state = action.payload
    end

    return state
  end,

  -- TODO: add more reducers.
})

-- ============================================================================
-- Root Reducer
-- ============================================================================

--- @type WuxReducer<{global: GlobalState, perchar: PercharState}>
Reducers.rootReducer = Wux:CombineReducers({
  global = Reducers.globalReducer,
  perchar = Reducers.percharReducer
})
