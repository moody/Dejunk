local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - exclusions
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:SetGlobalExclusions(value)
  return { type = ActionTypes.Global.SET_EXCLUSIONS, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharExclusions(value)
  return { type = ActionTypes.Perchar.SET_EXCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - exclusions
-- ============================================================================

--- Returns a new reducer for `exclusions` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<table>
function ReducerFactories.exclusions(defaultState, actionTypes)
  --- @param state table
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.exclusions)

    if action.type == actionTypes.SET_EXCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
