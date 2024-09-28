local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - inclusions
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:SetGlobalInclusions(value)
  return { type = ActionTypes.Global.SET_INCLUSIONS, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharInclusions(value)
  return { type = ActionTypes.Perchar.SET_INCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - inclusions
-- ============================================================================

--- Returns a new reducer for `inclusions` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<table>
function ReducerFactories.inclusions(defaultState, actionTypes)
  --- @param state table
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.inclusions)

    if action.type == actionTypes.SET_INCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
