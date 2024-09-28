local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local StateManager = Addon:GetModule("StateManager")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class ItemQualityCheckBoxValues
--- @field poor? boolean
--- @field common? boolean
--- @field uncommon? boolean
--- @field rare? boolean
--- @field epic? boolean

-- ============================================================================
-- Actions - itemQualityCheckBoxes
-- ============================================================================

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT or
      ActionTypes.Global.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT or
      ActionTypes.Global.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesIncludeBelowItemLevel(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL or
      ActionTypes.Global.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesIncludeByQuality(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY or
      ActionTypes.Global.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesIncludeUnsuitableEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT or
      ActionTypes.Global.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT
  return { type = actionType, payload = value }
end

-- ============================================================================
-- ReducerFactories - itemQualityCheckBoxes
-- ============================================================================

--- Returns a new reducer for `itemQualityCheckBoxes` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState | PercharState
--- @param actionTypes ActionTypesGlobal | ActionTypesPerchar
function ReducerFactories.itemQualityCheckBoxes(defaultState, actionTypes)
  return Wux:CombineReducers({
    --- Reducer for `excludeUnboundEquipment`.
    --- @param state ItemQualityCheckBoxValues
    --- @param action WuxAction
    excludeUnboundEquipment = function(state, action)
      state = Wux:Coalesce(state, defaultState.itemQualityCheckBoxes.excludeUnboundEquipment)

      if action.type == actionTypes.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT then
        local newState = Wux:ShallowCopy(state)
        for k, v in pairs(action.payload) do newState[k] = v end
        return newState
      end

      return state
    end,

    --- Reducer for `excludeWarbandEquipment`.
    --- @param state ItemQualityCheckBoxValues
    --- @param action WuxAction
    excludeWarbandEquipment = function(state, action)
      state = Wux:Coalesce(state, defaultState.itemQualityCheckBoxes.excludeWarbandEquipment)

      if action.type == actionTypes.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT then
        local newState = Wux:ShallowCopy(state)
        for k, v in pairs(action.payload) do newState[k] = v end
        return newState
      end

      return state
    end,

    --- Reducer for `includeBelowItemLevel`.
    --- @param state ItemQualityCheckBoxValues
    --- @param action WuxAction
    includeBelowItemLevel = function(state, action)
      state = Wux:Coalesce(state, defaultState.itemQualityCheckBoxes.includeBelowItemLevel)

      if action.type == actionTypes.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL then
        local newState = Wux:ShallowCopy(state)
        for k, v in pairs(action.payload) do newState[k] = v end
        return newState
      end

      return state
    end,

    --- Reducer for `includeByQuality`.
    --- @param state ItemQualityCheckBoxValues
    --- @param action WuxAction
    includeByQuality = function(state, action)
      state = Wux:Coalesce(state, defaultState.itemQualityCheckBoxes.includeByQuality)

      if action.type == actionTypes.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY then
        local newState = Wux:ShallowCopy(state)
        for k, v in pairs(action.payload) do newState[k] = v end
        return newState
      end

      return state
    end,

    --- Reducer for `includeUnsuitableEquipment`.
    --- @param state ItemQualityCheckBoxValues
    --- @param action WuxAction
    includeUnsuitableEquipment = function(state, action)
      state = Wux:Coalesce(state, defaultState.itemQualityCheckBoxes.includeUnsuitableEquipment)

      if action.type == actionTypes.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT then
        local newState = Wux:ShallowCopy(state)
        for k, v in pairs(action.payload) do newState[k] = v end
        return newState
      end

      return state
    end,
  })
end
