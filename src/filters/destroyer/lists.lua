local _, Addon = ...
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L
local ListManager = Addon.ListManager

function Filter:Run(item)
  if ListManager:IsOnList("Destroyables", item.ItemID) then
    return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.DESTROYABLES_TEXT)
  end

  if
    DB.Profile.DestroyInclusions and
    ListManager:IsOnList("Inclusions", item.ItemID)
  then
    return "JUNK", L.REASON_DESTROY_INCLUSIONS_TEXT
  end

  if
    DB.Profile.DestroyIgnoreExclusions and
    ListManager:IsOnList("Exclusions", item.ItemID)
  then
    return "NOT_JUNK", L.REASON_DESTROY_IGNORE_EXCLUSIONS_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
