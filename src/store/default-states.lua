local Addon = select(2, ...) ---@type Addon
local L = Addon:GetModule("Locale")

--- @class DefaultStates
local DefaultStates = Addon:GetModule("DefaultStates")

--- Bump whenever a state change requires a migration.
DefaultStates.CURRENT_VERSION = 1

DefaultStates.DEFAULT_PROFILE_ID = "DEFAULT_PROFILE"

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- Example: `{ ["itemId"] = true, ... }`
--- @alias ItemIdMap table<string, boolean>

--- @class ItemQualitiesState
--- @field poor boolean
--- @field common boolean
--- @field uncommon boolean
--- @field rare boolean
--- @field epic boolean

-- ============================================================================
-- DefaultStates - Global
-- ============================================================================

--- Default state for global settings.
--- @class GlobalState
DefaultStates.Global = {
  autoJunkFrame = false,
  chatMessages = true,
  itemIcons = false,
  itemTooltips = true,
  merchantButton = true,
  minimapIcon = { hide = false },
  safeDestroy = true,
  safeSell = false,

  --- @type ItemIdMap
  inclusions = {},
  --- @type ItemIdMap
  exclusions = {},

  points = {
    mainWindow = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    junkFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    lootableFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    transportFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    profilesFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    merchantButton = { point = "TOPLEFT", relativeTo = "MerchantFrame", relativePoint = "TOPLEFT", offsetX = 60, offsetY = -28 }
  }
}

-- ============================================================================
-- DefaultStates - Profiles
-- ============================================================================

--- @class ProfilesState
DefaultStates.Profiles = {
  activeProfileId = DefaultStates.DEFAULT_PROFILE_ID,

  --- Maps player character keys to profile IDs.
  --- Example: `{ ["<character-key>"] = "<profile-id>", ... }`
  --- @type table<string, string>
  characterMap = {},

  --- Maps profile IDs to profiles.
  --- Example: `{ ["<profile-id>"] = <ProfileState>, ... }`
  --- @type table<string, ProfileState>
  profileMap = {}
}

-- ============================================================================
-- DefaultStates - Profile
-- ============================================================================

--- Default state for a new profile.
--- @class ProfileState
DefaultStates.Profile = {
  id = DefaultStates.DEFAULT_PROFILE_ID,
  name = L.DEFAULT_PROFILE_NAME,
  settings = {
    autoRepair = false,
    autoSell = false,

    excludeAboveItemLevel = {
      enabled = false,
      value = 0,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    excludeEquipmentSets = true,
    excludeUnboundEquipment = {
      enabled = false,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    excludeWarbandEquipment = {
      enabled = false,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },

    includeBelowItemLevel = {
      enabled = false,
      value = 0,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    includeByQuality = {
      enabled = true,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = false, uncommon = false, rare = false, epic = false }
    },
    includeUnsuitableEquipment = {
      enabled = false,
      --- @type ItemQualitiesState
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    includeArtifactRelics = false,

    --- @type ItemIdMap
    inclusions = {},
    --- @type ItemIdMap
    exclusions = {},
  }
}
