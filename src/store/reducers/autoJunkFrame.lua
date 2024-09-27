local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - autoJunkFrame
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoJunkFrame(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_AUTO_JUNK_FRAME or
      ActionTypes.Global.SET_AUTO_JUNK_FRAME
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - autoJunkFrame
-- ============================================================================

--- Returns a new reducer for `autoJunkFrame` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.autoJunkFrame(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.autoJunkFrame)

    if action.type == actionTypes.SET_AUTO_JUNK_FRAME then
      return action.payload
    end

    return state
  end
end
