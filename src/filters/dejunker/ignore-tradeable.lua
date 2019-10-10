local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.IgnoreTradeable then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if DTL:IsTradeable() then
        return "NOT_JUNK", L.REASON_IGNORE_TRADEABLE_TEXT
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
