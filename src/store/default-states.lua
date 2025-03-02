local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class DefaultStates
local DefaultStates = Addon:GetModule("DefaultStates")

--- Base default state.
--- @class BaseDefaultState
local DEFAULT_STATE = {
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

  inclusions = { --[[ ["itemId"] = true, ... ]] },
  exclusions = { --[[ ["itemId"] = true, ... ]] },

  itemQualityCheckBoxes = {
    excludeUnboundEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    excludeWarbandEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    includeBelowItemLevel = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    includeByQuality = { poor = true, common = false, uncommon = false, rare = false, epic = false },
    includeUnsuitableEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
  }
}

--- Global default state.
--- @class GlobalState : BaseDefaultState
DefaultStates.Global = Wux:DeepCopy(DEFAULT_STATE)
DefaultStates.Global.chatMessages = true
DefaultStates.Global.itemIcons = false
DefaultStates.Global.itemTooltips = true
DefaultStates.Global.merchantButton = true
DefaultStates.Global.minimapIcon = { hide = false }
DefaultStates.Global.points = {
  mainWindow = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  junkFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  transportFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  merchantButton = { point = "TOPLEFT", relativeTo = "MerchantFrame", relativePoint = "TOPLEFT", offsetX = 60, offsetY = -28 }
}

-- Per character default state.
--- @class PercharState : BaseDefaultState
DefaultStates.Perchar = Wux:DeepCopy(DEFAULT_STATE)
DefaultStates.Perchar.characterSpecificSettings = false
