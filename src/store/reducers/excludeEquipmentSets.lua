local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - excludeEquipmentSets
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeEquipmentSets(value)
  return { type = ActionTypes.Perchar.SET_EXCLUDE_EQUIPMENT_SETS, payload = value }
end

-- ============================================================================
-- ReducerFactories - excludeEquipmentSets
-- ============================================================================

--- Returns a new reducer for `excludeEquipmentSets` using the given `defaultState` and `actionTypes`.
--- @param defaultState PercharState
--- @param actionTypes ActionTypesPerchar
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
