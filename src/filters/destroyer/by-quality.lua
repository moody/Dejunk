local _, Addon = ...
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

function Filter:Run(item)
  if
    (DB.Profile.DestroyPoor and item.Quality == LE_ITEM_QUALITY_POOR)
  then
    return "JUNK", L.REASON_DESTROY_BY_QUALITY_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
