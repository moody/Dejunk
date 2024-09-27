local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - includeUnsuitableEquipment
-- ============================================================================

--- Returns a new reducer for `includeUnsuitableEquipment` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.includeUnsuitableEquipment(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.includeUnsuitableEquipment)

    if action.type == actionTypes.SET_INCLUDE_UNSUITABLE_EQUIPMENT then
      return action.payload
    end

    return state
  end
end
