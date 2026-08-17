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
function Actions:SetPercharInclusions(value)
  return { type = ActionTypes.Perchar.SET_INCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - inclusions
-- ============================================================================

--- Returns a new reducer for perchar `inclusions`.
--- @return WuxReducer<ItemIdMap>
function ReducerFactories.percharInclusions()
  return function(state, action)
    state = Wux:Coalesce(state, DefaultStates.Perchar.inclusions)

    if action.type == ActionTypes.Perchar.SET_INCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
