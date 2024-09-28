local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - excludeWarbandEquipment
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeWarbandEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT or
      ActionTypes.Global.SET_EXCLUDE_WARBAND_EQUIPMENT
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - excludeWarbandEquipment
-- ============================================================================

--- Returns a new reducer for `excludeWarbandEquipment` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.excludeWarbandEquipment(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.excludeWarbandEquipment)

    if action.type == actionTypes.SET_EXCLUDE_WARBAND_EQUIPMENT then
      return action.payload
    end

    return state
  end
end
