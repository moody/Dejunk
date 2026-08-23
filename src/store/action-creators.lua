local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class ActionCreators
local ActionCreators = Addon:GetModule("ActionCreators")

-- ============================================================================
-- ActionCreators - Global
-- ============================================================================

ActionCreators.Global = {
  --- Action creator for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
  --- @type WuxActionCreator<boolean>
  setAutoJunkFrame = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_JUNK_FRAME),

  --- Action creator for `ActionTypes.Global.SET_AUTO_REPAIR`.
  --- @type WuxActionCreator<boolean>
  setAutoRepair = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_REPAIR),

  --- Action creator for `ActionTypes.Global.SET_AUTO_SELL`.
  --- @type WuxActionCreator<boolean>
  setAutoSell = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_SELL),

  --- Action creator for `ActionTypes.Global.SET_CHAT_MESSAGES`.
  --- @type WuxActionCreator<boolean>
  setChatMessages = Addon.Wux:CreateActionCreator(ActionTypes.Global.SET_CHAT_MESSAGES)
}

-- ============================================================================
-- ActionCreators - Perchar
-- ============================================================================

ActionCreators.Perchar = {}
