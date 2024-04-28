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

  -- Junk.
  autoJunkFrame = false,
  autoRepair = false,
  autoSell = false,
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
GLOBAL_DEFAULT_STATE.minimapIcon = { hide = false }

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

  -- Auto junk frame.
  autoJunkFrame = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.autoJunkFrame)

    if action.type == "global/autoJunkFrame/set" then
      state = action.payload
    end

    return state
  end,

  -- Auto repair.
  autoRepair = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.autoRepair)

    if action.type == "global/autoRepair/set" then
      state = action.payload
    end

    return state
  end,

  -- Auto sell.
  autoSell = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.autoSell)

    if action.type == "global/autoSell/set" then
      state = action.payload
    end

    return state
  end,

  -- Safe mode.
  safeMode = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.safeMode)

    if action.type == "global/safeMode/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude equipment sets.
  excludeEquipmentSets = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.excludeEquipmentSets)

    if action.type == "global/excludeEquipmentSets/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude unbound equipment.
  excludeUnboundEquipment = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.excludeUnboundEquipment)

    if action.type == "global/excludeUnboundEquipment/set" then
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

  -- Inclusions.
  inclusions = function(state, action)
    return Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.inclusions)
  end,

  -- Exclusions.
  exclusions = function(state, action)
    return Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.exclusions)
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

  -- Item tooltips.
  itemTooltips = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.itemTooltips)

    if action.type == "perchar/itemTooltips/set" then
      state = action.payload
    end

    return state
  end,

  -- Merchant button.
  merchantButton = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.merchantButton)

    if action.type == "perchar/merchantButton/set" then
      state = action.payload
    end

    return state
  end,

  -- Auto junk frame.
  autoJunkFrame = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.autoJunkFrame)

    if action.type == "perchar/autoJunkFrame/set" then
      state = action.payload
    end

    return state
  end,

  -- Auto repair.
  autoRepair = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.autoRepair)

    if action.type == "perchar/autoRepair/set" then
      state = action.payload
    end

    return state
  end,

  -- Auto sell.
  autoSell = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.autoSell)

    if action.type == "perchar/autoSell/set" then
      state = action.payload
    end

    return state
  end,

  -- Safe mode.
  safeMode = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.safeMode)

    if action.type == "perchar/safeMode/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude equipment sets.
  excludeEquipmentSets = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.excludeEquipmentSets)

    if action.type == "perchar/excludeEquipmentSets/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude unbound equipment.
  excludeUnboundEquipment = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.excludeUnboundEquipment)

    if action.type == "perchar/excludeUnboundEquipment/set" then
      state = action.payload
    end

    return state
  end,

  -- Inclusions.
  inclusions = function(state, action)
    return Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.inclusions)
  end,

  -- Exclusions.
  exclusions = function(state, action)
    return Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.exclusions)
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
