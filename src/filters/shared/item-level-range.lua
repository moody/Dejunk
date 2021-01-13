local _, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local L = Addon.Libs.L
local Utils = Addon.Utils

local SELL_REASON, DESTROY_REASON = Addon.Filters:SharedReason(
  L.BY_TYPE_TEXT,
  L.ITEM_LEVEL_RANGE_TEXT .. " (%s-%s)"
)

local function isInRange(item, range, reason)
  if item.ItemLevel >= range.min and item.ItemLevel <= range.max then
    return "JUNK", reason:format(
      DCL:ColorString(range.min, Colors.Yellow),
      DCL:ColorString(range.max, Colors.Yellow)
    )
  end

  return "PASS"
end

-- Dejunker
Addon.Filters:Add(Addon.Dejunker, {
  Run = function(_, item)
    if
      DB.Profile.sell.byType.itemLevelRange.enabled and
      Utils:IsEquipmentItem(item) and
      Utils:ItemCanBeSold(item)
    then
      return isInRange(
        item,
        DB.Profile.sell.byType.itemLevelRange,
        SELL_REASON
      )
    end

    return "PASS"
  end
})

-- Destroyer
Addon.Filters:Add(Addon.Destroyer, {
  Run = function(_, item)
    if
      DB.Profile.destroy.byType.itemLevelRange.enabled and
      Utils:IsEquipmentItem(item) and
      Utils:ItemCanBeDestroyed(item)
    then
      return isInRange(
        item,
        DB.Profile.destroy.byType.itemLevelRange,
        DESTROY_REASON
      )
    end

    return "PASS"
  end
})
