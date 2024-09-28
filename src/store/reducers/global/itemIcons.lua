local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - itemIcons
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetItemIcons(value)
  return { type = ActionTypes.Global.SET_ITEM_ICONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - itemIcons
-- ============================================================================

--- Returns a new reducer for `itemIcons` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<boolean>
function ReducerFactories.itemIcons(defaultState, actionTypes)
  --- @param state boolean
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.itemIcons)

    if action.type == actionTypes.SET_ITEM_ICONS then
      return action.payload
    end

    return state
  end
end
