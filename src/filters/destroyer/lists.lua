local _, Addon = ...
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if Lists.destroy.exclusions:Has(item.ItemID) then
      return "NOT_JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(
        Lists.destroy.exclusions.locale
      )
    end

    if Lists.destroy.inclusions:Has(item.ItemID) then
      return "JUNK", L.REASON_ITEM_ON_LIST_TEXT:format(
        Lists.destroy.inclusions.locale
      )
    end

    return "PASS"
  end
})
