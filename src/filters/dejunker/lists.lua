local _, Addon = ...
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

local GLOBAL_EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.exclusions.global.locale
)

local GLOBAL_INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.inclusions.global.locale
)

local PROFILE_EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.exclusions.profile.locale
)

local PROFILE_INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.sell.inclusions.profile.locale
)

Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    -- If the item will be destroyed, just sell it
    if Filters:Run(Destroyer, item) then
      return "JUNK", L.REASON_SELL_ITEM_TO_BE_DESTROYED
    end

    -- Profile lists.
    if Lists.sell.exclusions.profile:Has(item.ItemID) then
      return "NOT_JUNK", PROFILE_EXCLUDE_REASON
    end

    if Lists.sell.inclusions.profile:Has(item.ItemID) then
      return "JUNK", PROFILE_INCLUDE_REASON
    end

    -- Global lists.
    if Lists.sell.exclusions.global:Has(item.ItemID) then
      return "NOT_JUNK", GLOBAL_EXCLUDE_REASON
    end

    if Lists.sell.inclusions.global:Has(item.ItemID) then
      return "JUNK", GLOBAL_INCLUDE_REASON
    end

    return "PASS"
  end
})
