local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
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
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_INCLUDE_BY_QUALITY or
      ActionTypes.Global.SET_INCLUDE_BY_QUALITY
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - includeByQuality
-- ============================================================================

--- Returns a new reducer for `includeByQuality` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
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
