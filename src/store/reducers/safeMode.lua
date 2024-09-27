local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - safeMode
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetSafeMode(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_SAFE_MODE or
      ActionTypes.Global.SET_SAFE_MODE
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - safeMode
-- ============================================================================

--- Returns a new reducer for `safeMode` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.safeMode(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.safeMode)

    if action.type == actionTypes.SET_SAFE_MODE then
      return action.payload
    end

    return state
  end
end
