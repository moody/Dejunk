local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - autoJunkFrame
-- ============================================================================

--- Returns a new reducer for `autoJunkFrame` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.autoJunkFrame(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.autoJunkFrame)

    if action.type == actionTypes.SET_AUTO_JUNK_FRAME then
      return action.payload
    end

    return state
  end
end
