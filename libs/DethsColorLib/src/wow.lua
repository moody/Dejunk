local _, Addon = ...
local DCL = Addon.DethsColorLib
if DCL.__loaded then return end

local GetClassInfo = _G.GetClassInfo
local GetItemQualityColor = _G.GetItemQualityColor
local GetNumClasses = _G.GetNumClasses
local pairs = pairs
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local select = select

local ItemQuality do
  local q = _G.Enum.ItemQuality
  ItemQuality = {
    Poor = _G.LE_ITEM_QUALITY_POOR or q.Poor,
    Common = _G.LE_ITEM_QUALITY_COMMON or q.Common,
    Uncommon = _G.LE_ITEM_QUALITY_UNCOMMON or q.Uncommon,
    Rare = _G.LE_ITEM_QUALITY_RARE or q.Rare,
    Epic = _G.LE_ITEM_QUALITY_EPIC or q.Epic,
    Legendary = _G.LE_ITEM_QUALITY_LEGENDARY or q.Legendary,
    Artifact = _G.LE_ITEM_QUALITY_ARTIFACT or q.Artifact,
    Heirloom = _G.LE_ITEM_QUALITY_HEIRLOOM or q.Heirloom,
    WoWToken = _G.LE_ITEM_QUALITY_WOW_TOKEN or q.WoWToken
  }
end

-- ============================================================================
-- Wow Colors, DCL:GetColorByQuality(), DCL:GetColorByClassID()
-- ============================================================================

DCL.Wow = {
  Poor = ItemQuality.Poor,
  Common = ItemQuality.Common,
  Uncommon = ItemQuality.Uncommon,
  Rare = ItemQuality.Rare,
  Epic = ItemQuality.Epic,
  Legendary = ItemQuality.Legendary,
  Artifact = ItemQuality.Artifact,
  Heirloom = ItemQuality.Heirloom,
  WowToken = ItemQuality.WoWToken
}

-- Add quality colors
for k, v in pairs(DCL.Wow) do
  DCL.Wow[k] = select(4, GetItemQualityColor(v)):sub(3)
end

-- Add class colors by class key
for classKey, info in pairs(RAID_CLASS_COLORS) do
  DCL.Wow[classKey] = info.colorStr:sub(3)
end

DCL:HexTableToRGBA(DCL.Wow)

do -- GetColorByQuality()
  local colorByQuality = {
    [ItemQuality.Poor] = DCL.Wow.Poor,
    [ItemQuality.Common] = DCL.Wow.Common,
    [ItemQuality.Uncommon] = DCL.Wow.Uncommon,
    [ItemQuality.Rare] = DCL.Wow.Rare,
    [ItemQuality.Epic] = DCL.Wow.Epic,
    [ItemQuality.Legendary] = DCL.Wow.Legendary,
    [ItemQuality.Artifact] = DCL.Wow.Artifact,
    [ItemQuality.Heirloom] = DCL.Wow.Heirloom,
    [ItemQuality.WoWToken] = DCL.Wow.WowToken
  }

  -- Returns an rgba table specified by item quality.
  -- @param quality - a numeric value between ItemQuality.Poor and ItemQuality.WoWToken
  function DCL:GetColorByQuality(quality)
    return colorByQuality[quality] or error("invalid item quality: "..tostring(quality))
  end
end

-- GetColorByClassID() (currently not available in Classic)
if GetNumClasses and GetClassInfo then
  local colorByClassID = {}

  -- Add colors by class id
  for i=1, GetNumClasses() do
    local _, key = GetClassInfo(i)
    colorByClassID[i] = DCL.Wow[key]
  end

  -- Returns an rgba table specified by class id.
  -- @param classID - a numeric value between 1 and GetNumClasses()
  function DCL:GetColorByClassID(classID)
    return colorByClassID[classID] or error("invalid class id: "..tostring(classID))
  end
end
