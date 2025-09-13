local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - includeByTsmDisenchant
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:SetIncludeByTsmDisenchant(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.SET_INCLUDE_BY_TSM_DISENCHANT or
      ActionTypes.Global.SET_INCLUDE_BY_TSM_DISENCHANT
  return { type = actionType, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:PatchIncludeByTsmDisenchant(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.PATCH_INCLUDE_BY_TSM_DISENCHANT or
      ActionTypes.Global.PATCH_INCLUDE_BY_TSM_DISENCHANT
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - includeByTsmDisenchant
-- ============================================================================

--- Returns a new reducer for `includeByTsmDisenchant` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
--- @return WuxReducer<boolean>
function ReducerFactories.includeByTsmDisenchant(defaultState, actionTypes)
  --- @param state table
  --- @param action WuxAction
  return function(state, action)
    state = Wux:Coalesce(state, defaultState.includeByTsmDisenchant)

    if action.type == actionTypes.SET_INCLUDE_BY_TSM_DISENCHANT then
      return Wux:DeepCopy(action.payload)
    end

    if action.type == actionTypes.PATCH_INCLUDE_BY_TSM_DISENCHANT then
      return Wux:Merge(state, action.payload)
    end

    return state
  end
end
