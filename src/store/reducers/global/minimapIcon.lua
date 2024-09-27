local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - minimapIcon
-- ============================================================================

--- Returns a new reducer for `minimapIcon` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<table>
function ReducerFactories.minimapIcon(defaultState, actionTypes)
  --- @param state table
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.minimapIcon)

    if action.type == actionTypes.PATCH_MINIMAP_ICON then
      local newState = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do newState[k] = v end
      return newState
    end

    return state
  end
end
