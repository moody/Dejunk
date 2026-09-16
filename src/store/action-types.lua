local Addon = select(2, ...) ---@type Addon

--- @class ActionTypes
local ActionTypes = Addon:GetModule("ActionTypes")

-- ============================================================================
-- ActionTypes - Global
-- ============================================================================

--- @class ActionTypesGlobal
ActionTypes.Global = {
  SET_AUTO_JUNK_FRAME = "global/autoJunkFrame/set",
  SET_CHAT_MESSAGES = "global/chatMessages/set",
  SET_ITEM_ICONS = "global/itemIcons/set",
  SET_ITEM_TOOLTIPS = "global/itemTooltips/set",
  SET_MERCHANT_BUTTON = "global/merchantButton/set",
  SET_SAFE_DESTROY = "global/safeDestroy/set",
  SET_SAFE_SELL = "global/safeSell/set",

  SET_INCLUSIONS = "global/inclusions/set",
  SET_EXCLUSIONS = "global/exclusions/set",

  PATCH_MINIMAP_ICON = "global/minimapIcon/patch",
  RESET_JUNK_FRAME_POINT = "global/points/junkFrame/reset",
  RESET_LOOTABLE_FRAME_POINT = "global/points/lootableFrame/reset",
  RESET_MAIN_WINDOW_POINT = "global/points/mainWindow/reset",
  RESET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/reset",
  RESET_PROFILES_FRAME_POINT = "global/points/profilesFrame/reset",
  RESET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/reset",
  SET_JUNK_FRAME_POINT = "global/points/junkFrame/set",
  SET_LOOTABLE_FRAME_POINT = "global/points/lootableFrame/set",
  SET_MAIN_WINDOW_POINT = "global/points/mainWindow/set",
  SET_MERCHANT_BUTTON_POINT = "global/points/merchantButton/set",
  SET_PROFILES_FRAME_POINT = "global/points/profilesFrame/set",
  SET_TRANSPORT_FRAME_POINT = "global/points/transportFrame/set",
}

-- ============================================================================
-- ActionTypes - Profiles
-- ============================================================================

--- @class ActionTypesProfiles
ActionTypes.Profiles = {
  CREATE_PROFILE = "profiles/create",
  ASSIGN_PROFILE = "profiles/assign",
  RENAME_PROFILE = "profiles/rename",
  DELETE_PROFILE = "profiles/delete",
}

-- ============================================================================
-- ActionTypes - Profile
-- ============================================================================

--- @class ActionTypesProfile
ActionTypes.Profile = {
  SET_PROFILE_NAME = "profile/name/set",

  SET_AUTO_REPAIR = "profile/autoRepair/set",
  SET_AUTO_SELL = "profile/autoSell/set",

  MERGE_INCLUDE_BELOW_ITEM_LEVEL = "profile/includeBelowItemLevel/merge",
  SET_INCLUDE_ARTIFACT_RELICS = "profile/includeArtifactRelics/set",
  MERGE_INCLUDE_BY_QUALITY = "profile/includeByQuality/merge",
  SET_INCLUDE_UNSUITABLE_EQUIPMENT = "profile/includeUnsuitableEquipment/set",

  MERGE_EXCLUDE_ABOVE_ITEM_LEVEL = "profile/excludeAboveItemLevel/merge",
  SET_EXCLUDE_EQUIPMENT_SETS = "profile/excludeEquipmentSets/set",
  MERGE_EXCLUDE_UNBOUND_EQUIPMENT = "profile/excludeUnboundEquipment/merge",
  MERGE_EXCLUDE_WARBAND_EQUIPMENT = "profile/excludeWarbandEquipment/merge",

  SET_INCLUSIONS = "profile/inclusions/set",
  SET_EXCLUSIONS = "profile/exclusions/set",

  ItemQualityCheckBoxes = {
    PATCH_INCLUDE_UNSUITABLE_EQUIPMENT = "profile/itemQualityCheckBoxes/includeUnsuitableEquipment/patch",
  },
}
