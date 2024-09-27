local Addon = select(2, ...) ---@type Addon
local StateManager = Addon:GetModule("StateManager")

--- @class Actions
local Actions = Addon:GetModule("Actions")

Actions.Types = {
  --- @class ActionTypesGlobal
  Global = {
    ItemQualityCheckBoxes = {
      PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
      PATCH_EXCLUDE_WARBAND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
      PATCH_INCLUDE_BY_QUALITY = "global/itemQualityCheckBoxes/includeByQuality/patch",
    },
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "global/includeBelowItemLevel/patch",
    PATCH_MINIMAP_ICON = "global/minimapIcon/patch",
    RESET_JUNK_FRAME_POINT = "global/points/junkFrame/reset",
    RESET_MAIN_WINDOW_POINT = "global/points/mainWindow/reset",
    RESET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/reset",
    RESET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/reset",
    SET_AUTO_JUNK_FRAME = "global/autoJunkFrame/set",
    SET_AUTO_REPAIR = "global/autoRepair/set",
    SET_AUTO_SELL = "global/autoSell/set",
    SET_CHAT_MESSAGES = "global/chatMessages/set",
    SET_EXCLUDE_EQUIPMENT_SETS = "global/excludeEquipmentSets/set",
    SET_EXCLUDE_UNBOUND_EQUIPMENT = "global/excludeUnboundEquipment/set",
    SET_EXCLUDE_WARBAND_EQUIPMENT = "global/excludeWarbandEquipment/set",
    SET_EXCLUSIONS = "global/exclusions/set",
    SET_INCLUDE_ARTIFACT_RELICS = "global/includeArtifactRelics/set",
    SET_INCLUDE_BY_QUALITY = "global/includeByQuality/set",
    SET_INCLUDE_UNSUITABLE_EQUIPMENT = "global/includeUnsuitableEquipment/set",
    SET_INCLUSIONS = "global/inclusions/set",
    SET_ITEM_ICONS = "global/itemIcons/set",
    SET_ITEM_TOOLTIPS = "global/itemTooltips/set",
    SET_JUNK_FRAME_POINT = "global/points/junkFrame/set",
    SET_MAIN_WINDOW_POINT = "global/points/mainWindow/set",
    SET_MERCHANT_BUTTON = "global/merchantButton/set",
    SET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/set",
    SET_SAFE_MODE = "global/safeMode/set",
    SET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/set",
  },
  --- @class ActionTypesPerchar
  Perchar = {
    ItemQualityCheckBoxes = {
      PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
      PATCH_EXCLUDE_WARBAND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
      PATCH_INCLUDE_BY_QUALITY = "perchar/itemQualityCheckBoxes/includeByQuality/patch",
    },
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "perchar/includeBelowItemLevel/patch",
    SET_AUTO_JUNK_FRAME = "perchar/autoJunkFrame/set",
    SET_AUTO_REPAIR = "perchar/autoRepair/set",
    SET_AUTO_SELL = "perchar/autoSell/set",
    SET_EXCLUDE_EQUIPMENT_SETS = "perchar/excludeEquipmentSets/set",
    SET_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/excludeUnboundEquipment/set",
    SET_EXCLUDE_WARBAND_EQUIPMENT = "perchar/excludeWarbandEquipment/set",
    SET_EXCLUSIONS = "perchar/exclusions/set",
    SET_INCLUDE_ARTIFACT_RELICS = "perchar/includeArtifactRelics/set",
    SET_INCLUDE_BY_QUALITY = "perchar/includeByQuality/set",
    SET_INCLUDE_UNSUITABLE_EQUIPMENT = "perchar/includeUnsuitableEquipment/set",
    SET_INCLUSIONS = "perchar/inclusions/set",
    SET_SAFE_MODE = "perchar/safeMode/set",
    TOGGLE_CHARACTER_SPECIFIC_SETTINGS = "perchar/characterSpecificSettings/toggle",
  }
}

-- ============================================================================
-- Global
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetChatMessages(value)
  return { type = Actions.Types.Global.SET_CHAT_MESSAGES, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetItemIcons(value)
  return { type = Actions.Types.Global.SET_ITEM_ICONS, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetItemTooltips(value)
  return { type = Actions.Types.Global.SET_ITEM_TOOLTIPS, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetMerchantButton(value)
  return { type = Actions.Types.Global.SET_MERCHANT_BUTTON, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:PatchMinimapIcon(value)
  return { type = Actions.Types.Global.PATCH_MINIMAP_ICON, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetGlobalInclusions(value)
  return { type = Actions.Types.Global.SET_INCLUSIONS, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetGlobalExclusions(value)
  return { type = Actions.Types.Global.SET_EXCLUSIONS, payload = value }
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
  return { type = Actions.Types.Perchar.TOGGLE_CHARACTER_SPECIFIC_SETTINGS }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharInclusions(value)
  return { type = Actions.Types.Perchar.SET_INCLUSIONS, payload = value }
end

--- @param value table
--- @return WuxAction
function Actions:SetPercharExclusions(value)
  return { type = Actions.Types.Perchar.SET_EXCLUSIONS, payload = value }
end

-- ============================================================================
-- General
-- ============================================================================

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoJunkFrame(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_AUTO_JUNK_FRAME or
      Actions.Types.Global.SET_AUTO_JUNK_FRAME
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoRepair(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_AUTO_REPAIR or
      Actions.Types.Global.SET_AUTO_REPAIR
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetAutoSell(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_AUTO_SELL or
      Actions.Types.Global.SET_AUTO_SELL
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetSafeMode(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_SAFE_MODE or
      Actions.Types.Global.SET_SAFE_MODE
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeEquipmentSets(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_EXCLUDE_EQUIPMENT_SETS or
      Actions.Types.Global.SET_EXCLUDE_EQUIPMENT_SETS
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetExcludeUnboundEquipment(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_EXCLUDE_UNBOUND_EQUIPMENT or
      Actions.Types.Global.SET_EXCLUDE_UNBOUND_EQUIPMENT
  return { type = actionType, payload = value }
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
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.PATCH_INCLUDE_BELOW_ITEM_LEVEL or
      Actions.Types.Global.PATCH_INCLUDE_BELOW_ITEM_LEVEL
  return { type = actionType, payload = value }
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
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_INCLUDE_UNSUITABLE_EQUIPMENT or
      Actions.Types.Global.SET_INCLUDE_UNSUITABLE_EQUIPMENT
  return { type = actionType, payload = value }
end

--- @param value boolean
--- @return WuxAction
function Actions:SetIncludeArtifactRelics(value)
  local actionType = StateManager:IsCharacterSpecificSettings() and
      Actions.Types.Perchar.SET_INCLUDE_ARTIFACT_RELICS or
      Actions.Types.Global.SET_INCLUDE_ARTIFACT_RELICS
  return { type = actionType, payload = value }
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
