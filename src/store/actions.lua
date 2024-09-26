local Addon = select(2, ...) ---@type Addon
local StateManager = Addon:GetModule("StateManager")

--- @class Actions
local Actions = Addon:GetModule("Actions")

Actions.Types = {
  Global = {
    ItemQualityCheckBoxes = {
      PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
      PATCH_EXCLUDE_WARBAND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
      PATCH_INCLUDE_BY_QUALITY = "global/itemQualityCheckBoxes/includeByQuality/patch",
    },
    RESET_JUNK_FRAME_POINT = "global/points/junkFrame/reset",
    RESET_MAIN_WINDOW_POINT = "global/points/mainWindow/reset",
    RESET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/reset",
    RESET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/reset",
    SET_EXCLUDE_WARBAND_EQUIPMENT = "global/excludeWarbandEquipment/set",
    SET_INCLUDE_BY_QUALITY = "global/includeByQuality/set",
    SET_JUNK_FRAME_POINT = "global/points/junkFrame/set",
    SET_MAIN_WINDOW_POINT = "global/points/mainWindow/set",
    SET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/set",
    SET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/set",
  },
  Perchar = {
    ItemQualityCheckBoxes = {
      PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
      PATCH_EXCLUDE_WARBAND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
      PATCH_INCLUDE_BY_QUALITY = "perchar/itemQualityCheckBoxes/includeByQuality/patch",
    },
    SET_EXCLUDE_WARBAND_EQUIPMENT = "perchar/excludeWarbandEquipment/set",
    SET_INCLUDE_BY_QUALITY = "perchar/includeByQuality/set",
  }
}

-- ============================================================================
-- Global
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetChatMessages(value)
  return { type = "global/chatMessages/set", payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetItemIcons(value)
  return { type = "global/itemIcons/set", payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetItemTooltips(value)
  return { type = "global/itemTooltips/set", payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetMerchantButton(value)
  return { type = "global/merchantButton/set", payload = value }
end

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

--- @param value table
--- @return WuxAction
function Actions:SetMainWindowPoint(value)
  return { type = Actions.Types.Global.SET_MAIN_WINDOW_POINT, payload = value }
end

--- @return WuxAction
function Actions:ResetMainWindowPoint()
  return { type = Actions.Types.Global.RESET_MAIN_WINDOW_POINT }
end

--- @param value table
--- @return WuxAction
function Actions:SetJunkFramePoint(value)
  return { type = Actions.Types.Global.SET_JUNK_FRAME_POINT, payload = value }
end

--- @return WuxAction
function Actions:ResetJunkFramePoint()
  return { type = Actions.Types.Global.RESET_JUNK_FRAME_POINT }
end

--- @param value table
--- @return WuxAction
function Actions:SetTransportFramePoint(value)
  return { type = Actions.Types.Global.SET_TRANSPORT_FRAME_POINT, payload = value }
end

--- @return WuxAction
function Actions:ResetTransportFramePoint()
  return { type = Actions.Types.Global.RESET_TRANSPORT_FRAME_POINT }
end

--- @param value table
--- @return WuxAction
function Actions:SetMerchantButtonPoint(value)
  return { type = Actions.Types.Global.SET_MERCHANT_BUTTON_POINT, payload = value }
end

--- @return WuxAction
function Actions:ResetMerchantButtonPoint()
  return { type = Actions.Types.Global.RESET_MERCHANT_BUTTON_POINT }
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
-- General
-- ============================================================================

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
function Actions:SetExcludeWarbandEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT or
      Actions.Types.Global.SET_EXCLUDE_WARBAND_EQUIPMENT
  return { type = actionType, payload = value }
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
function Actions:SetIncludeByQuality(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_INCLUDE_BY_QUALITY or
      Actions.Types.Global.SET_INCLUDE_BY_QUALITY
  return { type = actionType, payload = value }
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

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesExcludeUnboundEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT or
      Actions.Types.Global.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesExcludeWarbandEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT or
      Actions.Types.Global.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT
  return { type = actionType, payload = value }
end

--- @param value ItemQualityCheckBoxValues
--- @return WuxAction
function Actions:PatchItemQualityCheckBoxesIncludeByQuality(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY or
      Actions.Types.Global.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY
  return { type = actionType, payload = value }
end
