local _, Addon = ...
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

local EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.exclusions.locale
)

local INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.inclusions.locale
)

Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if Lists.destroy.exclusions:Has(item.ItemID) then
      return "NOT_JUNK", EXCLUDE_REASON
    end

    if Lists.destroy.inclusions:Has(item.ItemID) then
      return "JUNK", INCLUDE_REASON
    end

    return "PASS"
  end
})
