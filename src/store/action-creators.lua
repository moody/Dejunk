local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")

--- @class ActionCreators
local ActionCreators = Addon:GetModule("ActionCreators")

-- ============================================================================
-- ActionCreators - Global
-- ============================================================================

ActionCreators.Global = {
  --- Action creator for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
  --- @param value boolean
  --- @return WuxPayloadAction<boolean>
  setAutoJunkFrame = function(value)
    return { type = ActionTypes.Global.SET_AUTO_JUNK_FRAME, payload = value }
  end,

  --- Action creator for `ActionTypes.Global.SET_AUTO_REPAIR`.
  --- @param value boolean
  --- @return WuxPayloadAction<boolean>
  setAutoRepair = function(value)
    return { type = ActionTypes.Global.SET_AUTO_REPAIR, payload = value }
  end,

  --- Action creator for `ActionTypes.Global.SET_AUTO_SELL`.
  --- @param value boolean
  --- @return WuxPayloadAction<boolean>
  setAutoSell = function(value)
    return { type = ActionTypes.Global.SET_AUTO_SELL, payload = value }
  end,

  --- Action creator for `ActionTypes.Global.SET_CHAT_MESSAGES`.
  --- @param value boolean
  --- @return WuxPayloadAction<boolean>
  setChatMessages = function(value)
    return { type = ActionTypes.Global.SET_CHAT_MESSAGES, payload = value }
  end
}

-- ============================================================================
-- ActionCreators - Perchar
-- ============================================================================

ActionCreators.Perchar = {}
