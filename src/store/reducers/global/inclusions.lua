local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Actions
local Actions = Addon:GetModule("Actions")

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- Actions - inclusions
-- ============================================================================

--- @param value ItemIdMap
--- @return WuxAction
function Actions:SetGlobalInclusions(value)
  return { type = ActionTypes.Global.SET_INCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - inclusions
-- ============================================================================

--- Returns a new reducer for global `inclusions`.
--- @return WuxReducer<ItemIdMap>
function ReducerFactories.globalInclusions()
  return function(state, action)
    state = Wux:Coalesce(state, DefaultStates.Global.inclusions)

    if action.type == ActionTypes.Global.SET_INCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
