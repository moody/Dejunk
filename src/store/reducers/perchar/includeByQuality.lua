local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - includeByQuality
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeByQuality(value)
  return { type = ActionTypes.Perchar.SET_INCLUDE_BY_QUALITY, payload = value }
end

-- ============================================================================
-- ReducerFactories - includeByQuality
-- ============================================================================

--- Returns a new reducer for `includeByQuality` using the given `defaultState` and `actionTypes`.
--- @param defaultState PercharState
--- @param actionTypes ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.includeByQuality(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.includeByQuality)

    if action.type == actionTypes.SET_INCLUDE_BY_QUALITY then
      return action.payload
    end

    return state
  end
end
