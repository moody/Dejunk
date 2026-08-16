local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - excludeUnboundEquipment
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeUnboundEquipment(value)
  return { type = ActionTypes.Perchar.SET_EXCLUDE_UNBOUND_EQUIPMENT, payload = value }
end

-- ============================================================================
-- ReducerFactories - excludeUnboundEquipment
-- ============================================================================

--- Returns a new reducer for `excludeUnboundEquipment` using the given `defaultState` and `actionTypes`.
--- @param defaultState PercharState
--- @param actionTypes ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.excludeUnboundEquipment(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.excludeUnboundEquipment)

    if action.type == actionTypes.SET_EXCLUDE_UNBOUND_EQUIPMENT then
      return action.payload
    end

    return state
  end
end
