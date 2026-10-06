local Addon = select(2, ...) ---@type Addon
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")

--- @class ItemFilters
local ItemFilters = Addon:GetModule("ItemFilters")

--- @alias ItemFilterResult "JUNK" | "NOT_JUNK" | "PASS"

--- The filter decided that the item is junk.
--- @type ItemFilterResult
ItemFilters.JUNK = "JUNK"

--- The filter decided that the item is not junk.
--- @type ItemFilterResult
ItemFilters.NOT_JUNK = "NOT_JUNK"

--- The filter did not apply.
--- @type ItemFilterResult
ItemFilters.PASS = "PASS"

-- ============================================================================
-- ItemFilters
-- ============================================================================

--- Refundable items are never junk.
--- @param item BagItem
--- @return ItemFilterResult result, string? reason
function ItemFilters:Refundable(item)
  if Items:IsItemRefundable(item) then
    return self.NOT_JUNK, L.ITEM_IS_REFUNDABLE
  end

  return self.PASS
end

--- Locked items are never junk.
--- @param item BagItem
--- @return ItemFilterResult result, string? reason
function ItemFilters:Locked(item)
  if Items:IsItemLocked(item) then
    return self.NOT_JUNK, L.ITEM_IS_LOCKED
  end

  return self.PASS
end
