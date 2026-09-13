local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class ActionCreators
local ActionCreators = Addon:GetModule("ActionCreators")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class ItemQualityCheckBoxValues
--- @field poor? boolean
--- @field common? boolean
--- @field uncommon? boolean
--- @field rare? boolean
--- @field epic? boolean

--- @class CreateProfilePayload
--- @field profileId string
--- @field profileName string

--- @class AssignProfilePayload
--- @field characterKey string
--- @field profileId string

--- @class RenameProfilePayload
--- @field profileId string
--- @field profileName string

--- @class DeleteProfilePayload
--- @field profileId string

-- ============================================================================
-- ActionCreators - Global
-- ============================================================================

ActionCreators.Global = {
  --- Action creator for `ActionTypes.Global.SET_CHAT_MESSAGES`.
  --- @type WuxActionCreator<boolean>
  setChatMessages = Addon.Wux:CreateActionCreator(ActionTypes.Global.SET_CHAT_MESSAGES),

  --- Action creator for `ActionTypes.Global.SET_ITEM_ICONS`.
  --- @type WuxActionCreator<boolean>
  setItemIcons = Wux:CreateActionCreator(ActionTypes.Global.SET_ITEM_ICONS),

  --- Action creator for `ActionTypes.Global.SET_ITEM_TOOLTIPS`.
  --- @type WuxActionCreator<boolean>
  setItemTooltips = Wux:CreateActionCreator(ActionTypes.Global.SET_ITEM_TOOLTIPS),

  --- Action creator for `ActionTypes.Global.SET_MERCHANT_BUTTON`.
  --- @type WuxActionCreator<boolean>
  setMerchantButton = Wux:CreateActionCreator(ActionTypes.Global.SET_MERCHANT_BUTTON),

  --- Action creator for `ActionTypes.Global.PATCH_MINIMAP_ICON`.
  --- @type WuxActionCreator<table<string, any>>
  patchMinimapIcon = Wux:CreateActionCreator(ActionTypes.Global.PATCH_MINIMAP_ICON),

  --- Action creator for `ActionTypes.Global.SET_INCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setInclusions = Wux:CreateActionCreator(ActionTypes.Global.SET_INCLUSIONS),

  --- Action creator for `ActionTypes.Global.SET_EXCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setExclusions = Wux:CreateActionCreator(ActionTypes.Global.SET_EXCLUSIONS),

  points = {
    mainWindow = {
      --- Action creator for `ActionTypes.Global.SET_MAIN_WINDOW_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_MAIN_WINDOW_POINT),

      --- Action creator for `ActionTypes.Global.RESET_MAIN_WINDOW_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_MAIN_WINDOW_POINT)
    },

    junkFrame = {
      --- Action creator for `ActionTypes.Global.SET_JUNK_FRAME_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_JUNK_FRAME_POINT),

      --- Action creator for `ActionTypes.Global.RESET_JUNK_FRAME_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_JUNK_FRAME_POINT)
    },

    transportFrame = {
      --- Action creator for `ActionTypes.Global.SET_TRANSPORT_FRAME_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_TRANSPORT_FRAME_POINT),

      --- Action creator for `ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT)
    },

    merchantButton = {
      --- Action creator for `ActionTypes.Global.SET_MERCHANT_BUTTON_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_MERCHANT_BUTTON_POINT),

      --- Action creator for `ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT)
    },

    profilesFrame = {
      --- Action creator for `ActionTypes.Global.SET_PROFILES_FRAME_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_PROFILES_FRAME_POINT),

      --- Action creator for `ActionTypes.Global.RESET_PROFILES_FRAME_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_PROFILES_FRAME_POINT)
    }
  }
}

-- ============================================================================
-- ActionCreators - Profiles
-- ============================================================================

ActionCreators.Profiles = {
  --- Action creator for `ActionTypes.Profiles.CREATE_PROFILE`.
  --- @type WuxActionCreator<CreateProfilePayload>
  createProfile = Wux:CreateActionCreator(ActionTypes.Profiles.CREATE_PROFILE),

  --- Action creator for `ActionTypes.Profiles.ASSIGN_PROFILE`.
  --- @type WuxActionCreator<AssignProfilePayload>
  assignProfile = Wux:CreateActionCreator(ActionTypes.Profiles.ASSIGN_PROFILE),

  --- Action creator for `ActionTypes.Profiles.RENAME_PROFILE`.
  --- @type WuxActionCreator<RenameProfilePayload>
  renameProfile = Wux:CreateActionCreator(ActionTypes.Profiles.RENAME_PROFILE),

  --- Action creator for `ActionTypes.Profiles.DELETE_PROFILE`.
  --- @type WuxActionCreator<DeleteProfilePayload>
  deleteProfile = Wux:CreateActionCreator(ActionTypes.Profiles.DELETE_PROFILE),
}

-- ============================================================================
-- ActionCreators - Profile
-- ============================================================================

ActionCreators.Profile = {
  --- Action creator for `ActionTypes.Profile.SET_PROFILE_NAME`.
  --- @type WuxActionCreator<string>
  setProfileName = Wux:CreateActionCreator(ActionTypes.Profile.SET_PROFILE_NAME),

  --- Action creator for `ActionTypes.Profile.SET_AUTO_JUNK_FRAME`.
  --- @type WuxActionCreator<boolean>
  setAutoJunkFrame = Wux:CreateActionCreator(ActionTypes.Profile.SET_AUTO_JUNK_FRAME),

  --- Action creator for `ActionTypes.Profile.SET_AUTO_REPAIR`.
  --- @type WuxActionCreator<boolean>
  setAutoRepair = Wux:CreateActionCreator(ActionTypes.Profile.SET_AUTO_REPAIR),

  --- Action creator for `ActionTypes.Profile.SET_AUTO_SELL`.
  --- @type WuxActionCreator<boolean>
  setAutoSell = Wux:CreateActionCreator(ActionTypes.Profile.SET_AUTO_SELL),

  --- Action creator for `ActionTypes.Profile.SET_SAFE_MODE`.
  --- @type WuxActionCreator<boolean>
  setSafeMode = Wux:CreateActionCreator(ActionTypes.Profile.SET_SAFE_MODE),

  --- Action creator for `ActionTypes.Profile.SET_EXCLUDE_EQUIPMENT_SETS`.
  --- @type WuxActionCreator<boolean>
  setExcludeEquipmentSets = Wux:CreateActionCreator(ActionTypes.Profile.SET_EXCLUDE_EQUIPMENT_SETS),

  --- Action creator for `ActionTypes.Profile.SET_EXCLUDE_UNBOUND_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setExcludeUnboundEquipment = Wux:CreateActionCreator(ActionTypes.Profile.SET_EXCLUDE_UNBOUND_EQUIPMENT),

  --- Action creator for `ActionTypes.Profile.SET_EXCLUDE_WARBAND_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setExcludeWarbandEquipment = Wux:CreateActionCreator(ActionTypes.Profile.SET_EXCLUDE_WARBAND_EQUIPMENT),

  --- Action creator for `ActionTypes.Profile.SET_INCLUDE_ARTIFACT_RELICS`.
  --- @type WuxActionCreator<boolean>
  setIncludeArtifactRelics = Wux:CreateActionCreator(ActionTypes.Profile.SET_INCLUDE_ARTIFACT_RELICS),

  --- Action creator for `ActionTypes.Profile.PATCH_INCLUDE_BELOW_ITEM_LEVEL`.
  --- @type WuxActionCreator<table<string, any>>
  patchIncludeBelowItemLevel = Wux:CreateActionCreator(ActionTypes.Profile.PATCH_INCLUDE_BELOW_ITEM_LEVEL),

  --- Action creator for `ActionTypes.Profile.SET_INCLUDE_BY_QUALITY`.
  --- @type WuxActionCreator<boolean>
  setIncludeByQuality = Wux:CreateActionCreator(ActionTypes.Profile.SET_INCLUDE_BY_QUALITY),

  --- Action creator for `ActionTypes.Profile.SET_INCLUDE_UNSUITABLE_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setIncludeUnsuitableEquipment = Wux:CreateActionCreator(ActionTypes.Profile.SET_INCLUDE_UNSUITABLE_EQUIPMENT),

  --- Action creator for `ActionTypes.Profile.SET_INCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setInclusions = Wux:CreateActionCreator(ActionTypes.Profile.SET_INCLUSIONS),

  --- Action creator for `ActionTypes.Profile.SET_EXCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setExclusions = Wux:CreateActionCreator(ActionTypes.Profile.SET_EXCLUSIONS),

  itemQualityCheckBoxes = {
    --- Action creator for `ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    excludeUnboundEquipment = Wux:CreateActionCreator(ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT),

    --- Action creator for `ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    excludeWarbandEquipment = Wux:CreateActionCreator(ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT),

    --- Action creator for `ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeBelowItemLevel = Wux:CreateActionCreator(ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL),

    --- Action creator for `ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeByQuality = Wux:CreateActionCreator(ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY),

    --- Action creator for `ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeUnsuitableEquipment = Wux:CreateActionCreator(ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT)
  }
}
