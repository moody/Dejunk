local _, Addon = ...
local Actions = Addon:GetModule("Actions") --- @class Actions
local StateManager = Addon:GetModule("StateManager") --- @type StateManager

-- ============================================================================
-- Global
-- ============================================================================

--- @param value table
--- @return WuxAction
function Actions:PatchMinimapIcon(value)
  return { type = "global/minimapIcon/patch", payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetGlobalInclusions(value)
  return { type = "global/inclusions/set", payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetGlobalExclusions(value)
  return { type = "global/exclusions/set", payload = value }
end

-- ============================================================================
-- Per Character
-- ============================================================================

--- @return WuxAction
function Actions:ToggleCharacterSpecificSettings()
  return { type = "perchar/characterSpecificSettings/toggle" }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharInclusions(value)
  return { type = "perchar/inclusions/set", payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharExclusions(value)
  return { type = "perchar/exclusions/set", payload = value }
end

-- ============================================================================
-- Common
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetChatMessages(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/chatMessages/set", payload = value }
  else
    return { type = "global/chatMessages/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetItemTooltips(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/itemTooltips/set", payload = value }
  else
    return { type = "global/itemTooltips/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetMerchantButton(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/merchantButton/set", payload = value }
  else
    return { type = "global/merchantButton/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoJunkFrame(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoJunkFrame/set", payload = value }
  else
    return { type = "global/autoJunkFrame/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoRepair(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoRepair/set", payload = value }
  else
    return { type = "global/autoRepair/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoSell(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/autoSell/set", payload = value }
  else
    return { type = "global/autoSell/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetSafeMode(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/safeMode/set", payload = value }
  else
    return { type = "global/safeMode/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeEquipmentSets(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/excludeEquipmentSets/set", payload = value }
  else
    return { type = "global/excludeEquipmentSets/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeUnboundEquipment(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/excludeUnboundEquipment/set", payload = value }
  else
    return { type = "global/excludeUnboundEquipment/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludePoorItems(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/includePoorItems/set", payload = value }
  else
    return { type = "global/includePoorItems/set", payload = value }
  end
end

--- @param value table
--- @return WuxAction
function Actions:PatchIncludeBelowItemLevel(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/includeBelowItemLevel/patch", payload = value }
  else
    return { type = "global/includeBelowItemLevel/patch", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeUnsuitableEquipment(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/includeUnsuitableEquipment/set", payload = value }
  else
    return { type = "global/includeUnsuitableEquipment/set", payload = value }
  end
end

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeArtifactRelics(value)
  if StateManager:IsCharacterSpecificSettings() then
    return { type = "perchar/includeArtifactRelics/set", payload = value }
  else
    return { type = "global/includeArtifactRelics/set", payload = value }
  end
end
