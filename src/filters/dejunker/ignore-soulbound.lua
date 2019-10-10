local _, Addon = ...
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

function Filter:Run(item)
  if
    DB.Profile.IgnoreSoulbound and
    item.Quality ~= LE_ITEM_QUALITY_POOR
  then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if DTL:IsSoulbound() then
        return "NOT_JUNK", L.REASON_IGNORE_SOULBOUND_TEXT
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
