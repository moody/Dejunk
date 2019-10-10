local _, Addon = ...
local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR

function Filter:Run(item)
  if
    DB.Profile.IgnoreConsumables and
    item.Class == Consts.CONSUMABLE_CLASS and
    item.Quality ~= LE_ITEM_QUALITY_POOR
  then
    return "NOT_JUNK", L.REASON_IGNORE_CONSUMABLES_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
