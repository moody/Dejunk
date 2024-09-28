local Addon = select(2, ...) ---@type Addon

--- @class ActionTypes
local ActionTypes = Addon:GetModule("ActionTypes")

--- @class ActionTypesGlobal
ActionTypes.Global = {
  ItemQualityCheckBoxes = {
    PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
    PATCH_EXCLUDE_WARBAND_EQUIPMENT = "global/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "global/itemQualityCheckBoxes/includeBelowItemLevel/patch",
    PATCH_INCLUDE_BY_QUALITY = "global/itemQualityCheckBoxes/includeByQuality/patch",
    PATCH_INCLUDE_UNSUITABLE_EQUIPMENT = "global/itemQualityCheckBoxes/includeUnsuitableEquipment/patch",
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
}

--- @class ActionTypesPerchar
ActionTypes.Perchar = {
  ItemQualityCheckBoxes = {
    PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
    PATCH_EXCLUDE_WARBAND_EQUIPMENT = "perchar/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "perchar/itemQualityCheckBoxes/includeBelowItemLevel/patch",
    PATCH_INCLUDE_BY_QUALITY = "perchar/itemQualityCheckBoxes/includeByQuality/patch",
    PATCH_INCLUDE_UNSUITABLE_EQUIPMENT = "perchar/itemQualityCheckBoxes/includeUnsuitableEquipment/patch",
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
