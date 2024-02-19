local _, Addon = ...
local Actions = Addon:GetModule("Actions") --- @class Actions
local StateManager = Addon:GetModule("StateManager") --- @type StateManager

-- ============================================================================
-- Common
-- ============================================================================

--- @return WuxAction
function Actions:SetChatMessages(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/chatMessages/set", payload = value }
  else
    return { type = "global/chatMessages/set", payload = value }
  end
end

-- ============================================================================
-- Global
-- ============================================================================

-- TODO: add actions.

-- ============================================================================
-- Per Character
-- ============================================================================

--- @return WuxAction
function Actions:ToggleCharacterSpecificSettings()
  return { type = "perchar/characterSpecificSettings/toggle" }
end
