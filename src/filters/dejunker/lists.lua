local _, Addon = ...
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    -- If the item will be destroyed, just sell it
    if Filters:Run(Destroyer, item) then
      return "JUNK", L.REASON_SELL_ITEM_TO_BE_DESTROYED
    end

    if Lists.Exclusions:Has(item.ItemID) then
      return "NOT_JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.EXCLUSIONS_TEXT)
    end

    if Lists.Inclusions:Has(item.ItemID) then
      return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(L.INCLUSIONS_TEXT)
    end

    return "PASS"
  end
})
