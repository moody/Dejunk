local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - itemTooltips
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetItemTooltips(value)
  return { type = ActionTypes.Global.SET_ITEM_TOOLTIPS, payload = value }
end

-- ============================================================================
-- ReducerFactories - itemTooltips
-- ============================================================================

--- Returns a new reducer for `itemTooltips` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<boolean>
function ReducerFactories.itemTooltips(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.itemTooltips)

    if action.type == actionTypes.SET_ITEM_TOOLTIPS then
      return action.payload
    end

    return state
  end
end
