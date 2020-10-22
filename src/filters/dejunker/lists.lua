local _, Addon = ...
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

local EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.exclusions.locale
)

local INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.inclusions.locale
)

Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    -- If the item will be destroyed, just sell it
    if Filters:Run(Destroyer, item) then
      return "JUNK", L.REASON_SELL_ITEM_TO_BE_DESTROYED
    end

    if Lists.sell.exclusions:Has(item.ItemID) then
      return "NOT_JUNK", EXCLUDE_REASON
    end

    if Lists.sell.inclusions:Has(item.ItemID) then
      return "JUNK", INCLUDE_REASON
    end

    return "PASS"
  end
})
