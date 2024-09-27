local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - excludeEquipmentSets
-- ============================================================================

--- Returns a new reducer for `excludeEquipmentSets` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.excludeEquipmentSets(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.excludeEquipmentSets)

    if action.type == actionTypes.SET_EXCLUDE_EQUIPMENT_SETS then
      return action.payload
    end

    return state
  end
end
