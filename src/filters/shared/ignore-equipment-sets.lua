local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local EQUIPMENT_SETS_CAPTURE = _G.EQUIPMENT_SETS:gsub("%%s", "(.*)")
local L = Addon.Libs.L

local function isEquipmentSet(item)
  if not DTL:ScanBagSlot(item.Bag, item.Slot) then
    return Addon.Filters:IncompleteTooltipError()
  end

  if (not not DTL:Match(false, EQUIPMENT_SETS_CAPTURE)) then
    return "NOT_JUNK", L.REASON_IGNORE_EQUIPMENT_SETS_TEXT
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if DB.Profile.IgnoreEquipmentSets then
      return isEquipmentSet(item)
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if DB.Profile.DestroyIgnoreEquipmentSets then
      return isEquipmentSet(item)
    end

    return "PASS"
  end
})
