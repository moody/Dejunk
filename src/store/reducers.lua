local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class Reducers
local Reducers = Addon:GetModule("Reducers")

-- ============================================================================
-- Reducers - Global
-- ============================================================================

Reducers.Global = {
  --- Reducer for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
  autoJunkFrame = Wux:CreatePayloadReducer(
    ActionTypes.Global.SET_AUTO_JUNK_FRAME,
    DefaultStates.Global.autoJunkFrame
  ),

  --- Reducer for `ActionTypes.Global.SET_AUTO_REPAIR`.
  autoRepair = Wux:CreatePayloadReducer(
    ActionTypes.Global.SET_AUTO_REPAIR,
    DefaultStates.Global.autoRepair
  ),

  --- Reducer for `ActionTypes.Global.SET_AUTO_SELL`.
  autoSell = Wux:CreatePayloadReducer(
    ActionTypes.Global.SET_AUTO_SELL,
    DefaultStates.Global.autoSell
  )
}

-- ============================================================================
-- Reducers - Perchar
-- ============================================================================

Reducers.Perchar = {}
