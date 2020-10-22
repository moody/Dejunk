local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_TRADEABLE_TEXT
)

local function run(item, ignore, reason)
  if ignore.tradeable then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    end

    if DTL:IsTradeable() then
      return "NOT_JUNK", reason
    end
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, SELL_REASON)
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    return run(item, DB.Profile.destroy.ignore, DESTROY_REASON)
  end
})
