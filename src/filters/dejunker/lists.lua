local _, Addon = ...
local Filter = {}
local L = Addon.Libs.L
local Lists = Addon.Lists

function Filter:Run(item)
  if Lists.Exclusions:Has(item.ItemID) then
    return "NOT_JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.EXCLUSIONS_TEXT)
  end

  if Lists.Inclusions:Has(item.ItemID) then
    return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.INCLUSIONS_TEXT)
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
