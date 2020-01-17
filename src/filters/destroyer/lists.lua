local _, Addon = ...
local DB = Addon.DB
local Destroyables = Addon.Lists.Destroyables
local Filter = {}
local L = Addon.Libs.L
local Undestroyables = Addon.Lists.Undestroyables

function Filter:Run(item)
  if Undestroyables:Has(item.ItemID) then
    return "NOT_JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.UNDESTROYABLES_TEXT)
  end

  if Destroyables:Has(item.ItemID) then
    return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.DESTROYABLES_TEXT)
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
