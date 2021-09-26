local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L

local REASON = Addon.Filters:SellReason(
  L.IGNORE_TEXT,
  L.BY_TYPE_TEXT,
  L.IGNORE_EQUIPMENT_SETS_TEXT
)

local EQUIPMENT_SETS_CAPTURE = _G.EQUIPMENT_SETS:gsub("%%s", "(.*)")

local function run(item, ignore, reason)
  if ignore.equipmentSets then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    end

    if (not not DTL:Match(false, EQUIPMENT_SETS_CAPTURE)) then
      return "NOT_JUNK", reason
    end
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    return run(item, DB.Profile.sell.ignore, REASON)
  end
})
