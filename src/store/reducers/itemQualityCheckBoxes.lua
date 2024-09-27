local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

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
    end
  })
end
