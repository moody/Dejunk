local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - merchantButton
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetMerchantButton(value)
  return { type = ActionTypes.Global.SET_MERCHANT_BUTTON, payload = value }
end

-- ============================================================================
-- ReducerFactories - merchantButton
-- ============================================================================

--- Returns a new reducer for `merchantButton` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<boolean>
function ReducerFactories.merchantButton(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.merchantButton)

    if action.type == actionTypes.SET_MERCHANT_BUTTON then
      return action.payload
    end

    return state
  end
end
