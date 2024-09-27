local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - chatMessages
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetChatMessages(value)
  return { type = ActionTypes.Global.SET_CHAT_MESSAGES, payload = value }
end

-- ============================================================================
-- ReducerFactories - chatMessages
-- ============================================================================

--- Returns a new reducer for `chatMessages` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<boolean>
function ReducerFactories.chatMessages(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.chatMessages)

    if action.type == actionTypes.SET_CHAT_MESSAGES then
      return action.payload
    end

    return state
  end
end
