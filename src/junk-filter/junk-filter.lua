local Addon = select(2, ...) ---@type Addon
local BagItemsCache = Addon:GetModule("BagItemsCache")
local ItemFilters = Addon:GetModule("ItemFilters")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")

--- @class JunkFilter
local JunkFilter = Addon:GetModule("JunkFilter")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Comparison function for sorting items by price, quality, and name.
--- @param a BagItem
--- @param b BagItem
--- @return boolean
local function itemSortFunc(a, b)
  local aTotalPrice = a.price * a.quantity
  local bTotalPrice = b.price * b.quantity
  if aTotalPrice == bTotalPrice then
    if a.quality == b.quality then
      if a.name == b.name then
        return a.quantity < b.quantity
      end
      return a.name < b.name
    end
    return a.quality < b.quality
  end
  return aTotalPrice < bTotalPrice
end

--- Returns junk items as determined by the given `filterFunc`.
--- @param filterFunc fun(self: JunkFilter, item: BagItem): boolean, string?
--- @param items? BagItem[]
--- @param limit? integer
--- @param excludeLocked? boolean
--- @return BagItem[] junkItems
local function getJunkItems(filterFunc, items, limit, excludeLocked)
  items = BagItemsCache:GetItems(items)

  for i = #items, 1, -1 do
    local item = items[i]
    local isJunk, reason = filterFunc(JunkFilter, item)

    if isJunk then
      item.reason = reason
    else
      table.remove(items, i)
    end
  end

  table.sort(items, itemSortFunc)

  if limit or excludeLocked then
    local numItems = #items
    local numKept = 0

    -- Keep the first `limit` items, skipping locked ones if `excludeLocked` is set.
    for i = 1, numItems do
      if limit and numKept >= limit then break end

      local item = items[i]
      if not (excludeLocked and Items:IsItemLocked(item)) then
        numKept = numKept + 1
        items[numKept] = item
      end
    end

    for i = numItems, numKept + 1, -1 do items[i] = nil end
  end

  return items
end

-- ============================================================================
-- JunkFilter
-- ============================================================================

do -- Convenience methods.
  local items = {}

  --- Returns the number of sellable and destroyable junk items that are not locked.
  --- @return integer numSellable, integer numDestroyable
  function JunkFilter:GetNumJunkItems()
    local numSellable = #self:GetSellableJunkItems(items)
    local numDestroyable = #self:GetDestroyableJunkItems(items)
    return numSellable, numDestroyable
  end

  --- Returns the next sellable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkFilter:GetNextSellableJunkItem()
    self:GetSellableJunkItems(items, 1)
    return items[1]
  end

  --- Returns the next destroyable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkFilter:GetNextDestroyableJunkItem()
    self:GetDestroyableJunkItems(items, 1)
    return items[1]
  end
end

--- Creates or updates an array of sellable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] sellableItems
function JunkFilter:GetSellableJunkItems(items, limit)
  return getJunkItems(self.IsSellableJunkItem, items, limit, true)
end

--- Creates or updates an array of destroyable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] destroyableItems
function JunkFilter:GetDestroyableJunkItems(items, limit)
  return getJunkItems(self.IsDestroyableJunkItem, items, limit, true)
end

--- Creates or updates an array of junk items, including locked ones.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] junkItems
function JunkFilter:GetJunkItems(items, limit)
  return getJunkItems(self.IsJunkItem, items, limit)
end

--- Returns `true` and a reason string if the given `item` is junk and can be sold.
--- @param item BagItem
--- @return boolean isSellableJunk, string? reason
function JunkFilter:IsSellableJunkItem(item)
  return self:IsJunkItem(item, "SELL")
end

--- Returns `true` and a reason string if the given `item` is junk and can be destroyed.
--- @param item BagItem
--- @return boolean isDestroyableJunk, string? reason
function JunkFilter:IsDestroyableJunkItem(item)
  return self:IsJunkItem(item, "DESTROY")
end

--- Returns `true` and a reason string if the given `item` is junk for the given `filterType`, or for
--- either type if none is given.
--- @param item BagItem
--- @param filterType? ItemFilterType
--- @return boolean isJunk, string? reason
function JunkFilter:IsJunkItem(item, filterType)
  if not filterType then
    local isSellableJunk, sellReason = self:IsJunkItem(item, "SELL")
    if isSellableJunk then return true, sellReason end

    local isDestroyableJunk, destroyReason = self:IsJunkItem(item, "DESTROY")
    if isDestroyableJunk then return true, destroyReason end

    return false, sellReason or destroyReason
  end

  if not Items:IsItemStillInBags(item) then
    return false
  end

  -- Check if item can be sold or destroyed, depending on the filter type.
  if filterType == "SELL" and not Items:IsItemSellable(item) then
    return false, L.ITEM_CANNOT_BE_SOLD
  end

  if filterType == "DESTROY" and not Items:IsItemDestroyable(item) then
    return false, L.ITEM_CANNOT_BE_DESTROYED
  end

  --- @type ItemFilterResult, string?
  local result, reason

  -- Refundable.
  result, reason = ItemFilters:Refundable(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Locked.
  result, reason = ItemFilters:Locked(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  local profileSettings = StateManager:GetProfileState().settings

  -- Exclude equipment above item level. Runs before the lists so it can
  -- override an Inclusions match.
  result, reason = ItemFilters:ExcludeAboveItemLevel(item, profileSettings.excludeAboveItemLevel, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude above price.
  result, reason = ItemFilters:ExcludeAbovePrice(item, profileSettings.excludeAbovePrice, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Lists.
  result, reason = ItemFilters:ByLists(item)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude equipment sets.
  if not (Addon.IS_VANILLA or Addon.IS_TBC) then
    result, reason = ItemFilters:ExcludeEquipmentSets(item, profileSettings.excludeEquipmentSets, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude unbound equipment.
  result, reason = ItemFilters:ExcludeUnboundEquipment(item, profileSettings.excludeUnboundEquipment, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Exclude warband equipment.
  if Addon.IS_RETAIL then
    result, reason = ItemFilters:ExcludeWarbandEquipment(item, profileSettings.excludeWarbandEquipment, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- Exclude by equipment type.
  result, reason = ItemFilters:ExcludeByEquipmentType(item, profileSettings.excludeByEquipmentType, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by quality.
  result, reason = ItemFilters:IncludeByQuality(item, profileSettings.includeByQuality, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include below item level.
  result, reason = ItemFilters:IncludeBelowItemLevel(item, profileSettings.includeBelowItemLevel, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include below price.
  result, reason = ItemFilters:IncludeBelowPrice(item, profileSettings.includeBelowPrice, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include by equipment type.
  result, reason = ItemFilters:IncludeByEquipmentType(item, profileSettings.includeByEquipmentType, filterType)
  if result ~= ItemFilters.PASS then
    return result == ItemFilters.JUNK, reason
  end

  -- Include artifact relics.
  if Addon.IS_RETAIL then
    result, reason = ItemFilters:IncludeArtifactRelics(item, profileSettings.includeArtifactRelics, filterType)
    if result ~= ItemFilters.PASS then
      return result == ItemFilters.JUNK, reason
    end
  end

  -- No filters matched.
  return false, L.NO_FILTERS_MATCHED
end
