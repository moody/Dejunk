local _, Addon = ...
local Filters = Addon.Filters
local L = Addon.Libs.L
local Lists = Addon.Lists

local GLOBAL_EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.exclusions.global.locale
)

local GLOBAL_INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.inclusions.global.locale
)

local PROFILE_EXCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.exclusions.profile.locale
)

local PROFILE_INCLUDE_REASON = Filters:Reason(
  L.LIST_TEXT,
  Lists.destroy.inclusions.profile.locale
)

Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    -- Profile lists.
    if Lists.destroy.exclusions.profile:Has(item.ItemID) then
      return "NOT_JUNK", PROFILE_EXCLUDE_REASON
    end

    if Lists.destroy.inclusions.profile:Has(item.ItemID) then
      return "JUNK", PROFILE_INCLUDE_REASON
    end

    -- Global lists.
    if Lists.destroy.exclusions.global:Has(item.ItemID) then
      return "NOT_JUNK", GLOBAL_EXCLUDE_REASON
    end

    if Lists.destroy.inclusions.global:Has(item.ItemID) then
      return "JUNK", GLOBAL_INCLUDE_REASON
    end

    return "PASS"
  end
})
