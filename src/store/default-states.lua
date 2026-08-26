local Addon = select(2, ...) ---@type Addon

--- @class DefaultStates
local DefaultStates = Addon:GetModule("DefaultStates")

--- Example: `{ ["itemId"] = true, ... }`
--- @alias ItemIdMap table<string, boolean>

--- Global default state.
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
    merchantButton = { point = "TOPLEFT", relativeTo = "MerchantFrame", relativePoint = "TOPLEFT", offsetX = 60, offsetY = -28 }
  }
}

-- Per character default state.
--- @class PercharState
DefaultStates.Perchar = {
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
