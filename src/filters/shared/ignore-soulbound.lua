local _, Addon = ...
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L
local ItemQuality = Addon.ItemQuality

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
      DB.Profile.sell.ignore.soulbound and
      item.Quality ~= ItemQuality.Poor
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
      DB.Profile.destroy.ignore.soulbound and
      item.Quality ~= ItemQuality.Poor
    then
      return isSoulbound(item)
    end

    return "PASS"
  end
})
