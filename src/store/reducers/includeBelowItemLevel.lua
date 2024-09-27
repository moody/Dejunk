local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - includeBelowItemLevel
-- ============================================================================

--- Returns a new reducer for `includeBelowItemLevel` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<table>
function ReducerFactories.includeBelowItemLevel(defaultState, actionTypes)
  --- @param state table
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.includeBelowItemLevel)

    if action.type == actionTypes.PATCH_INCLUDE_BELOW_ITEM_LEVEL then
      local newState = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do newState[k] = v end
      return newState
    end

    return state
  end
end
