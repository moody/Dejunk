local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")

--- @class ActionCreators
local ActionCreators = Addon:GetModule("ActionCreators")
ActionCreators.Global = {}
ActionCreators.Perchar = {}

-- ============================================================================
-- ActionCreators - Global
-- ============================================================================

--- Action creator for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
--- @type WuxActionCreator<boolean>
function ActionCreators.Global.setAutoJunkFrame(value)
  return { type = ActionTypes.Global.SET_AUTO_JUNK_FRAME, payload = value }
end

-- ============================================================================
-- ActionCreators - Perchar
-- ============================================================================
