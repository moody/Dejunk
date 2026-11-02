local Addon = select(2, ...) ---@type Addon
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")

--- @class JunkItemsCache
local JunkItemsCache = Addon:GetModule("JunkItemsCache")

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
-- JunkItemsCache
-- ============================================================================

do -- Convenience methods.
  local items = {}

  --- Returns the number of sellable and destroyable junk items that are not locked.
  --- @return integer numSellable, integer numDestroyable
  function JunkItemsCache:GetNumJunkItems()
    local numSellable = #self:GetSellableJunkItems(items)
    local numDestroyable = #self:GetDestroyableJunkItems(items)
    return numSellable, numDestroyable
  end

  --- Returns the next sellable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkItemsCache:GetNextSellableJunkItem()
    self:GetSellableJunkItems(items, 1)
    return items[1]
  end

  --- Returns the next destroyable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkItemsCache:GetNextDestroyableJunkItem()
    self:GetDestroyableJunkItems(items, 1)
    return items[1]
  end

  --- Returns the number of junk items for selling that cannot be sold right now.
  --- @return integer
  function JunkItemsCache:GetNumSellBlockedJunkItems()
    local numBlocked = 0

    for _, item in ipairs(BagItemsCache:GetItems(items)) do
      if JunkFilter:IsJunkItem(item, "SELL") and JunkFilter:GetSellBlockReason(item) then
        numBlocked = numBlocked + 1
      end
    end

    return numBlocked
  end
end

--- Creates or updates an array of sellable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] sellableItems
function JunkItemsCache:GetSellableJunkItems(items, limit)
  return getJunkItems(JunkFilter.IsSellableJunkItem, items, limit, true)
end

--- Creates or updates an array of destroyable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] destroyableItems
function JunkItemsCache:GetDestroyableJunkItems(items, limit)
  return getJunkItems(JunkFilter.IsDestroyableJunkItem, items, limit, true)
end

--- Creates or updates an array of junk items, including locked ones.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] junkItems
function JunkItemsCache:GetJunkItems(items, limit)
  return getJunkItems(JunkFilter.IsJunkItem, items, limit)
end
