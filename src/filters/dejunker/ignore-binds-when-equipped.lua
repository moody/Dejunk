local _, Addon = ...
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

function Filter:Run(item)
  if
    DB.Profile.IgnoreBindsWhenEquipped and
    item.Quality ~= LE_ITEM_QUALITY_POOR
  then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if DTL:IsBindsWhenEquipped() then
        return "NOT_JUNK", L.REASON_IGNORE_BOE_TEXT
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
