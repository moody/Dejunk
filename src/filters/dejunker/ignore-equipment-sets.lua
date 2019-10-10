local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local EQUIPMENT_SETS_CAPTURE = _G.EQUIPMENT_SETS:gsub("%%s", "(.*)")
local Filter = {}
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.IgnoreEquipmentSets then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if (not not DTL:Match(false, EQUIPMENT_SETS_CAPTURE)) then
        return "NOT_JUNK", L.REASON_IGNORE_EQUIPMENT_SETS_TEXT
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
