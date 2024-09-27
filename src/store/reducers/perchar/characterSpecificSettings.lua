local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - characterSpecificSettings
-- ============================================================================

--- Returns a new reducer for `characterSpecificSettings` using the given `defaultState` and `actionTypes`.
--- @param defaultState PercharState
--- @param actionTypes ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.characterSpecificSettings(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.characterSpecificSettings)

    if action.type == actionTypes.TOGGLE_CHARACTER_SPECIFIC_SETTINGS then
      return not state
    end

    return state
  end
end
