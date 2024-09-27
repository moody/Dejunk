local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - characterSpecificSettings
-- ============================================================================

--- @return WuxAction
function Actions:ToggleCharacterSpecificSettings()
  return { type = ActionTypes.Perchar.TOGGLE_CHARACTER_SPECIFIC_SETTINGS }
end

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
