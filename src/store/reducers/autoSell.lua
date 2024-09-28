local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - autoSell
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoSell(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_AUTO_SELL or
      ActionTypes.Global.SET_AUTO_SELL
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - autoSell
-- ============================================================================

--- Returns a new reducer for `autoSell` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.autoSell(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.autoSell)

    if action.type == actionTypes.SET_AUTO_SELL then
      return action.payload
    end

    return state
  end
end
