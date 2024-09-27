local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

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
