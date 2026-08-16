local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - includeUnsuitableEquipment
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeUnsuitableEquipment(value)
  return { type = ActionTypes.Perchar.SET_INCLUDE_UNSUITABLE_EQUIPMENT, payload = value }
end

-- ============================================================================
-- ReducerFactories - includeUnsuitableEquipment
-- ============================================================================

--- Returns a new reducer for `includeUnsuitableEquipment` using the given `defaultState` and `actionTypes`.
--- @param defaultState PercharState
--- @param actionTypes ActionTypesPerchar
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
