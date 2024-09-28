local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - autoRepair
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoRepair(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_AUTO_REPAIR or
      ActionTypes.Global.SET_AUTO_REPAIR
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - autoRepair
-- ============================================================================

--- Returns a new reducer for `autoRepair` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.autoRepair(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.autoRepair)

    if action.type == actionTypes.SET_AUTO_REPAIR then
      return action.payload
    end

    return state
  end
end
