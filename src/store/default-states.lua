local Addon = select(2, ...) ---@type Addon
local L = Addon:GetModule("Locale")

--- @class DefaultStates
local DefaultStates = Addon:GetModule("DefaultStates")

--- Bump whenever a state change requires a migration.
DefaultStates.CURRENT_VERSION = 2

DefaultStates.DEFAULT_PROFILE_ID = "DEFAULT_PROFILE"

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- Example: `{ ["itemId"] = true, ... }`
--- @alias ItemIdMap table<string, boolean>

--- @alias ItemQualityKey "poor" | "common" | "uncommon" | "rare" | "epic"

--- Whether each item quality is selected.
--- @class ItemQualitiesState
--- @field poor boolean
--- @field common boolean
--- @field uncommon boolean
--- @field rare boolean
--- @field epic boolean

--- Option that can be turned on or off.
--- @class ToggleOptionState
--- @field enabled boolean

--- Option that applies to selling, destroying, or both.
--- @class ScopeOptionState : ToggleOptionState
--- @field scope ItemFilterScope

--- Option limited to the selected item qualities.
--- @class QualitiesOptionState : ScopeOptionState
--- @field qualities ItemQualitiesState

--- Qualities option with an item level.
--- @class ItemLevelOptionState : QualitiesOptionState
--- @field value integer Item level threshold.

--- Qualities option that compares the price of an item's stack.
--- @class PriceOptionState : QualitiesOptionState
--- @field value integer Price threshold in copper.

--- Qualities option limited to the selected armor and weapon types.
--- @class EquipmentTypeOptionState : QualitiesOptionState
--- @field armor table<integer, boolean> Selected armor subclasses.
--- @field weapons table<integer, boolean> Selected weapon subclasses.

-- ============================================================================
-- DefaultStates - Global
-- ============================================================================

--- Default state for global settings.
--- @class GlobalState
DefaultStates.Global = {
  autoJunkFrame = false,
  autoLootableFrame = false,
  chatMessages = true,
  itemIcons = false,
  --- @type ItemIconStyle
  itemIconStyle = "SMALL",
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

    --- @type ItemLevelOptionState
    excludeAboveItemLevel = {
      enabled = false,
      value = 0,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    --- @type PriceOptionState
    excludeAbovePrice = {
      enabled = false,
      value = 0,
      scope = "DESTROY",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    --- @type EquipmentTypeOptionState
    excludeByEquipmentType = {
      enabled = false,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true },
      armor = {},
      weapons = {}
    },
    --- @type ScopeOptionState
    excludeEquipmentSets = { enabled = true, scope = "BOTH" },
    --- @type QualitiesOptionState
    excludeUnboundEquipment = {
      enabled = false,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    --- @type QualitiesOptionState
    excludeWarbandEquipment = {
      enabled = false,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },

    --- @type ItemLevelOptionState
    includeBelowItemLevel = {
      enabled = false,
      value = 0,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    --- @type PriceOptionState
    includeBelowPrice = {
      enabled = false,
      value = 0,
      scope = "SELL",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true }
    },
    --- @type EquipmentTypeOptionState
    includeByEquipmentType = {
      enabled = false,
      scope = "BOTH",
      qualities = { poor = true, common = true, uncommon = true, rare = true, epic = true },
      armor = {},
      weapons = {}
    },
    --- @type QualitiesOptionState
    includeByQuality = {
      enabled = true,
      scope = "BOTH",
      qualities = { poor = true, common = false, uncommon = false, rare = false, epic = false }
    },
    --- @type ScopeOptionState
    includeArtifactRelics = { enabled = false, scope = "BOTH" },

    --- @type ItemIdMap
    inclusions = {},
    --- @type ItemIdMap
    exclusions = {},
  }
}
