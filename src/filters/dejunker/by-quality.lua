local _, Addon = ...
local DB = Addon.DB
local Filter = {}
local L = Addon.Libs.L
local LE_ITEM_QUALITY_COMMON = _G.LE_ITEM_QUALITY_COMMON
local LE_ITEM_QUALITY_EPIC = _G.LE_ITEM_QUALITY_EPIC
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR
local LE_ITEM_QUALITY_RARE = _G.LE_ITEM_QUALITY_RARE
local LE_ITEM_QUALITY_UNCOMMON = _G.LE_ITEM_QUALITY_UNCOMMON

function Filter:Run(item)
  if
    (item.Quality == LE_ITEM_QUALITY_POOR and DB.Profile.SellPoor) or
    (item.Quality == LE_ITEM_QUALITY_COMMON and DB.Profile.SellCommon) or
    (item.Quality == LE_ITEM_QUALITY_UNCOMMON and DB.Profile.SellUncommon) or
    (item.Quality == LE_ITEM_QUALITY_RARE and DB.Profile.SellRare) or
    (item.Quality == LE_ITEM_QUALITY_EPIC and DB.Profile.SellEpic)
  then
    return "JUNK", L.REASON_SELL_BY_QUALITY_TEXT
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
