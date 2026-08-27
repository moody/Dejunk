local Addon = select(2, ...) ---@type Addon

--- @class ActionTypes
local ActionTypes = Addon:GetModule("ActionTypes")

-- ============================================================================
-- ActionTypes - Global
-- ============================================================================

--- @class ActionTypesGlobal
ActionTypes.Global = {
  SET_CHAT_MESSAGES = "global/chatMessages/set",
  SET_ITEM_ICONS = "global/itemIcons/set",
  SET_ITEM_TOOLTIPS = "global/itemTooltips/set",
  SET_MERCHANT_BUTTON = "global/merchantButton/set",

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
-- ActionTypes - Profiles
-- ============================================================================

--- @class ActionTypesProfiles
ActionTypes.Profiles = {
  CREATE_PROFILE = "profiles/create",
  ASSIGN_PROFILE = "profiles/assign",
}

-- ============================================================================
-- ActionTypes - Profile
-- ============================================================================

--- @class ActionTypesProfile
ActionTypes.Profile = {
  SET_PROFILE_NAME = "profile/name/set",

  SET_AUTO_JUNK_FRAME = "profile/autoJunkFrame/set",
  SET_AUTO_REPAIR = "profile/autoRepair/set",
  SET_AUTO_SELL = "profile/autoSell/set",
  SET_SAFE_MODE = "profile/safeMode/set",

  PATCH_INCLUDE_BELOW_ITEM_LEVEL = "profile/includeBelowItemLevel/patch",
  SET_INCLUDE_ARTIFACT_RELICS = "profile/includeArtifactRelics/set",
  SET_INCLUDE_BY_QUALITY = "profile/includeByQuality/set",
  SET_INCLUDE_UNSUITABLE_EQUIPMENT = "profile/includeUnsuitableEquipment/set",

  SET_EXCLUDE_EQUIPMENT_SETS = "profile/excludeEquipmentSets/set",
  SET_EXCLUDE_UNBOUND_EQUIPMENT = "profile/excludeUnboundEquipment/set",
  SET_EXCLUDE_WARBAND_EQUIPMENT = "profile/excludeWarbandEquipment/set",

  SET_INCLUSIONS = "profile/inclusions/set",
  SET_EXCLUSIONS = "profile/exclusions/set",

  ItemQualityCheckBoxes = {
    PATCH_EXCLUDE_UNBOUND_EQUIPMENT = "profile/itemQualityCheckBoxes/excludeUnboundEquipment/patch",
    PATCH_EXCLUDE_WARBAND_EQUIPMENT = "profile/itemQualityCheckBoxes/excludeWarbandEquipment/patch",
    PATCH_INCLUDE_BELOW_ITEM_LEVEL = "profile/itemQualityCheckBoxes/includeBelowItemLevel/patch",
    PATCH_INCLUDE_BY_QUALITY = "profile/itemQualityCheckBoxes/includeByQuality/patch",
    PATCH_INCLUDE_UNSUITABLE_EQUIPMENT = "profile/itemQualityCheckBoxes/includeUnsuitableEquipment/patch",
  },
}
