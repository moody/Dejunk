local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Reducers
local Reducers = Addon:GetModule("Reducers")
Reducers.Global = {}
Reducers.Perchar = {}

-- ============================================================================
-- Reducers - Global
-- ============================================================================

--- Reducer for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
--- @type WuxReducer<boolean>
function Reducers.Global.autoJunkFrame(state, action)
  state = Wux:Coalesce(state, DefaultStates.Global.autoJunkFrame)

  if action.type == ActionTypes.Global.SET_AUTO_JUNK_FRAME then
    return action.payload
  end

  return state
end

-- ============================================================================
-- Reducers - Perchar
-- ============================================================================
