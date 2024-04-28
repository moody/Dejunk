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

--- @return WuxAction
function Actions:SetItemTooltips(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/itemTooltips/set", payload = value }
  else
    return { type = "global/itemTooltips/set", payload = value }
  end
end

--- @return WuxAction
function Actions:SetMerchantButton(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/merchantButton/set", payload = value }
  else
    return { type = "global/merchantButton/set", payload = value }
  end
end

--- @return WuxAction
function Actions:SetAutoJunkFrame(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoJunkFrame/set", payload = value }
  else
    return { type = "global/autoJunkFrame/set", payload = value }
  end
end

--- @return WuxAction
function Actions:SetAutoRepair(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoRepair/set", payload = value }
  else
    return { type = "global/autoRepair/set", payload = value }
  end
end

--- @return WuxAction
function Actions:SetAutoSell(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoSell/set", payload = value }
  else
    return { type = "global/autoSell/set", payload = value }
  end
end

-- ============================================================================
-- Global
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:PatchMinimapIcon(value)
  return { type = "global/minimapIcon/patch", payload = value }
end

-- ============================================================================
-- Per Character
-- ============================================================================

--- @return WuxAction
function Actions:ToggleCharacterSpecificSettings()
  return { type = "perchar/characterSpecificSettings/toggle" }
end
