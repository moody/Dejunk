local _, Addon = ...
local Filter = {}
local L = Addon.Libs.L
local ListManager = Addon.ListManager

function Filter:Run(item)
  if ListManager:IsOnList("Exclusions", item.ItemID) then
    return "NOT_JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.EXCLUSIONS_TEXT)
  end

  if ListManager:IsOnList("Inclusions", item.ItemID) then
    return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.INCLUSIONS_TEXT)
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
