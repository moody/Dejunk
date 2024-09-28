local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - includeArtifactRelics
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeArtifactRelics(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_INCLUDE_ARTIFACT_RELICS or
      ActionTypes.Global.SET_INCLUDE_ARTIFACT_RELICS
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - includeArtifactRelics
-- ============================================================================

--- Returns a new reducer for `includeArtifactRelics` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.includeArtifactRelics(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.includeArtifactRelics)

    if action.type == actionTypes.SET_INCLUDE_ARTIFACT_RELICS then
      return action.payload
    end

    return state
  end
end
