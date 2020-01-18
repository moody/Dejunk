local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L

local function isTradeable(item)
  if not DTL:ScanBagSlot(item.Bag, item.Slot) then
    return Addon.Filters:IncompleteTooltipError()
  end

  if DTL:IsTradeable() then
    return "NOT_JUNK", L.REASON_IGNORE_TRADEABLE_TEXT
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if DB.Profile.IgnoreTradeable then
      return isTradeable(item)
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.DestroyIgnoreTradeable then
      return isTradeable(item)
    end

    return "PASS"
  end
})
