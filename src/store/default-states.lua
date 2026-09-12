local Addon = select(2, ...) ---@type Addon
local L = Addon:GetModule("Locale")

--- @class DefaultStates
local DefaultStates = Addon:GetModule("DefaultStates")

DefaultStates.DEFAULT_PROFILE_ID = "DEFAULT_PROFILE"

--- Example: `{ ["itemId"] = true, ... }`
--- @alias ItemIdMap table<string, boolean>

--- Default state for global settings.
--- @class GlobalState
DefaultStates.Global = {
  chatMessages = true,
  itemIcons = false,
  itemTooltips = true,
  merchantButton = true,
  minimapIcon = { hide = false },

  --- @type ItemIdMap
  inclusions = {},
  --- @type ItemIdMap
  exclusions = {},

  points = {
    mainWindow = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    junkFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    transportFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    profilesFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
    merchantButton = { point = "TOPLEFT", relativeTo = "MerchantFrame", relativePoint = "TOPLEFT", offsetX = 60, offsetY = -28 }
  }
}

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

--- Default state for a new profile.
--- @class ProfileState
DefaultStates.Profile = {
  id = DefaultStates.DEFAULT_PROFILE_ID,
  name = L.DEFAULT_PROFILE_NAME,
  settings = {
    autoJunkFrame = false,
    autoRepair = false,
    autoSell = false,
    safeMode = false,

    excludeEquipmentSets = true,
    excludeUnboundEquipment = false,
    excludeWarbandEquipment = false,

    includeBelowItemLevel = { enabled = false, value = 0 },
    includeByQuality = true,
    includeUnsuitableEquipment = false,
    includeArtifactRelics = false,

    --- @type ItemIdMap
    inclusions = {},
    --- @type ItemIdMap
    exclusions = {},

    itemQualityCheckBoxes = {
      excludeUnboundEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
      excludeWarbandEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
      includeBelowItemLevel = { poor = true, common = true, uncommon = true, rare = true, epic = true },
      includeByQuality = { poor = true, common = false, uncommon = false, rare = false, epic = false },
      includeUnsuitableEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    }
  }
}
