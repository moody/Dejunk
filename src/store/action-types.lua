local Addon = select(2, ...) ---@type Addon

--- @class ActionTypes
local ActionTypes = Addon:GetModule("ActionTypes")

-- ============================================================================
-- ActionTypes - Global
-- ============================================================================

--- @class ActionTypesGlobal
ActionTypes.Global = {
  SET_AUTO_JUNK_FRAME = "global/autoJunkFrame/set",
  SET_AUTO_REPAIR = "global/autoRepair/set",
  SET_AUTO_SELL = "global/autoSell/set",
  SET_CHAT_MESSAGES = "global/chatMessages/set",
  SET_ITEM_ICONS = "global/itemIcons/set",
  SET_ITEM_TOOLTIPS = "global/itemTooltips/set",
  SET_MERCHANT_BUTTON = "global/merchantButton/set",
  SET_SAFE_MODE = "global/safeMode/set",

  SET_INCLUSIONS = "global/inclusions/set",
  SET_EXCLUSIONS = "global/exclusions/set",

  PATCH_MINIMAP_ICON = "global/minimapIcon/patch",
  RESET_JUNK_FRAME_POINT = "global/points/junkFrame/reset",
  RESET_MAIN_WINDOW_POINT = "global/points/mainWindow/reset",
  RESET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/reset",
  RESET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/reset",
  SET_JUNK_FRAME_POINT = "global/points/junkFrame/set",
  SET_MAIN_WINDOW_POINT = "global/points/mainWindow/set",
  SET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/set",
  SET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/set",
}

-- ============================================================================
-- ActionTypes - Perchar
-- ============================================================================

--- @class ActionTypesPerchar
ActionTypes.Perchar = {
  PATCH_INCLUDE_BELOW_ITEM_LEVEL = "perchar/includeBelowItemLevel/patch",
  SET_INCLUDE_ARTIFACT_RELICS = "perchar/includeArtifactRelics/set",
  SET_INCLUDE_BY_QUALITY = "perchar/includeByQuality/set",
  SET_INCLUDE_UNSUITABLE_EQUIPMENT = "perchar/includeUnsuitableEquipment/set",

  SET_EXCLUDE_EQUIPMENT_SETS = "perchar/excludeEquipmentSets/set",
  SET_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/excludeUnboundEquipment/set",
  SET_EXCLUDE_WARBAND_EQUIPMENT = "perchar/excludeWarbandEquipment/set",

  SET_INCLUSIONS = "perchar/inclusions/set",
  SET_EXCLUSIONS = "perchar/exclusions/set",

  ItemQualityCheckBoxes = {
    PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
    PATCH_EXCLUDE_WARBAND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "perchar/itemQualityCheckBoxes/includeBelowItemLevel/patch",
    PATCH_INCLUDE_BY_QUALITY = "perchar/itemQualityCheckBoxes/includeByQuality/patch",
    PATCH_INCLUDE_UNSUITABLE_EQUIPMENT = "perchar/itemQualityCheckBoxes/includeUnsuitableEquipment/patch",
  },
}
