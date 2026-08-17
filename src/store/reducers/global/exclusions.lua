local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - exclusions
-- ============================================================================

--- @param value ItemIdMap
--- @return WuxAction
function Actions:SetGlobalExclusions(value)
  return { type = ActionTypes.Global.SET_EXCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - exclusions
-- ============================================================================

--- Returns a new reducer for global `exclusions`.
--- @return WuxReducer<ItemIdMap>
function ReducerFactories.globalExclusions()
  return function(state, action)
    state = Wux:Coalesce(state, DefaultStates.Global.exclusions)

    if action.type == ActionTypes.Global.SET_EXCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
