local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Action Types
-- ============================================================================

ActionTypes.Global.ADD_TSM_JUNK_ITEM = "global/tsmJunkItems/add"
ActionTypes.Global.REMOVE_TSM_JUNK_ITEM = "global/tsmJunkItems/remove"
ActionTypes.Perchar.ADD_TSM_JUNK_ITEM = "perchar/tsmJunkItems/add"
ActionTypes.Perchar.REMOVE_TSM_JUNK_ITEM = "perchar/tsmJunkItems/remove"

-- ============================================================================
-- Actions
-- ============================================================================

--- @param itemId number
--- @return WuxAction
function Actions:AddTsmJunkItem(itemId)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ADD_TSM_JUNK_ITEM or
      ActionTypes.Global.ADD_TSM_JUNK_ITEM
  return { type = actionType, payload = itemId }
end

--- @param itemId number
--- @return WuxAction
function Actions:RemoveTsmJunkItem(itemId)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.REMOVE_TSM_JUNK_ITEM or
      ActionTypes.Global.REMOVE_TSM_JUNK_ITEM
  return { type = actionType, payload = itemId }
end

-- ============================================================================
-- Reducer Factory
-- ============================================================================

--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<table<number, boolean>>
function ReducerFactories.tsmJunkItems(defaultState, actionTypes)
  --- @param state table<number, boolean>
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.tsmJunkItems)

    if action.type == actionTypes.ADD_TSM_JUNK_ITEM then
      local newState = Wux:DeepCopy(state)
      newState[action.payload] = true
      return newState
    end

    if action.type == actionTypes.REMOVE_TSM_JUNK_ITEM then
      local newState = Wux:DeepCopy(state)
      newState[action.payload] = nil
      return newState
    end

    return state
  end
end
