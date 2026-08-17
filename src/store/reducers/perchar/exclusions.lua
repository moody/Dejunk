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
function Actions:SetPercharExclusions(value)
  return { type = ActionTypes.Perchar.SET_EXCLUSIONS, payload = value }
end

-- ============================================================================
-- ReducerFactories - percharExclusions
-- ============================================================================

--- Returns a new reducer for perchar `exclusions`.
--- @return WuxReducer<ItemIdMap>
function ReducerFactories.percharExclusions()
  return function(state, action)
    state = Wux:Coalesce(state, DefaultStates.Perchar.exclusions)

    if action.type == ActionTypes.Perchar.SET_EXCLUSIONS then
      return Wux:ShallowCopy(action.payload)
    end

    return state
  end
end
