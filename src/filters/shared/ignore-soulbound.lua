local _, Addon = ...
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

local function isSoulbound(item)
  if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
  end

  if DTL:IsSoulbound() then
    return "NOT_JUNK", L.REASON_IGNORE_SOULBOUND_TEXT
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.IgnoreSoulbound and
      item.Quality ~= LE_ITEM_QUALITY_POOR
    then
      return isSoulbound(item)
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.DestroyIgnoreSoulbound and
      item.Quality ~= LE_ITEM_QUALITY_POOR
    then
      return isSoulbound(item)
    end

    return "PASS"
  end
})
