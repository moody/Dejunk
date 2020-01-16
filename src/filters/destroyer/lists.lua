local _, Addon = ...
local DB = Addon.DB
local Destroyables = Addon.Lists.Destroyables
local Exclusions = Addon.Lists.Exclusions
local Filter = {}
local Inclusions = Addon.Lists.Inclusions
local L = Addon.Libs.L

function Filter:Run(item)
  if DB.Profile.DestroyIgnoreExclusions and Exclusions:Has(item.ItemID) then
    return "NOT_JUNK", L.REASON_DESTROY_IGNORE_EXCLUSIONS_TEXT
  end

  if Destroyables:Has(item.ItemID) then
    return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.DESTROYABLES_TEXT)
  end

  if DB.Profile.DestroyInclusions and Inclusions:Has(item.ItemID) then
    return "JUNK", L.REASON_DESTROY_INCLUSIONS_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
