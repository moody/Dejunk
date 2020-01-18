local _, Addon = ...
local DCL = Addon.DethsColorLib
if DCL.__loaded then return end

local GetClassInfo = _G.GetClassInfo
local GetItemQualityColor = _G.GetItemQualityColor
local GetNumClasses = _G.GetNumClasses
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local select = select
local pairs = pairs

-- ============================================================================
-- Wow Colors, DCL:GetColorByQuality(), DCL:GetColorByClassID()
-- ============================================================================

DCL.Wow = {
  Poor = _G.LE_ITEM_QUALITY_POOR,
  Common = _G.LE_ITEM_QUALITY_COMMON,
  Uncommon = _G.LE_ITEM_QUALITY_UNCOMMON,
  Rare = _G.LE_ITEM_QUALITY_RARE,
  Epic = _G.LE_ITEM_QUALITY_EPIC,
  Legendary = _G.LE_ITEM_QUALITY_LEGENDARY,
  Artifact = _G.LE_ITEM_QUALITY_ARTIFACT,
  Heirloom = _G.LE_ITEM_QUALITY_HEIRLOOM,
  WowToken = _G.LE_ITEM_QUALITY_WOW_TOKEN
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
    [_G.LE_ITEM_QUALITY_POOR] = DCL.Wow.Poor,
    [_G.LE_ITEM_QUALITY_COMMON] = DCL.Wow.Common,
    [_G.LE_ITEM_QUALITY_UNCOMMON] = DCL.Wow.Uncommon,
    [_G.LE_ITEM_QUALITY_RARE] = DCL.Wow.Rare,
    [_G.LE_ITEM_QUALITY_EPIC] = DCL.Wow.Epic,
    [_G.LE_ITEM_QUALITY_LEGENDARY] = DCL.Wow.Legendary,
    [_G.LE_ITEM_QUALITY_ARTIFACT] = DCL.Wow.Artifact,
    [_G.LE_ITEM_QUALITY_HEIRLOOM] = DCL.Wow.Heirloom,
    [_G.LE_ITEM_QUALITY_WOW_TOKEN] = DCL.Wow.WowToken
  }

  -- Returns an rgba table specified by item quality.
  -- @param quality - a numeric value between LE_ITEM_QUALITY_POOR and LE_ITEM_QUALITY_WOW_TOKEN
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
