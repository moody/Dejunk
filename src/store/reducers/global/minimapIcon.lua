local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - minimapIcon
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:PatchMinimapIcon(value)
  return { type = ActionTypes.Global.PATCH_MINIMAP_ICON, payload = value }
end

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
