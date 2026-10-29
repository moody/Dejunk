local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local E = Addon:GetModule("Events")
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")
local EventManager = Addon:GetModule("EventManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class BagItemsCache
local BagItemsCache = Addon:GetModule("BagItemsCache")

--- Seconds between checks for whether the cache needs updating.
--- @type number
BagItemsCache.UPDATE_TICK_SECONDS = 0.1

--- Seconds that a burst of `BAG_UPDATE` events can hold back an update.
--- @type number
BagItemsCache.BURST_MAX_SECONDS = 2

--- Seconds between checks for whether an item's refund window has ended.
--- @type number
BagItemsCache.REFUND_POLL_SECONDS = 1

--- @type table<integer, BagItem>
local cache = {}

--- Whether the next tick updates the cache.
local isDirty = false

--- The time the current burst of `BAG_UPDATE` events started, or `nil` if there is none.
--- @type number?
local burstStartTime

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Marks the cache to be updated on the next tick.
local function markDirty()
  isDirty = true
end

--- Returns whether a burst of `BAG_UPDATE` events is holding back updates. A burst ends after `BURST_MAX_SECONDS`
--- even if `BAG_UPDATE_DELAYED` does not arrive.
--- @return boolean
local function isBurstActive()
  return burstStartTime ~= nil and B.Utils:GetTime() - burstStartTime < BagItemsCache.BURST_MAX_SECONDS
end

--- Returns the item cached for the `bag` and `slot`, if it exists.
--- @param bag integer
--- @param slot integer
--- @return BagItem
local function getCachedItem(bag, slot)
  return cache[BagItemsCache:GetSlotKey(bag, slot)]
end

--- Sets the item for the `bag` and `slot` in the cache.
--- @param bag integer
--- @param slot integer
--- @param item BagItem|nil
local function setCachedItem(bag, slot, item)
  cache[BagItemsCache:GetSlotKey(bag, slot)] = item
end

--- Updates the item cache and fires the `BagsUpdated` event.
local function updateCache()
  isDirty = false
  burstStartTime = nil

  EquipmentSetsCache:Refresh()

  for k in pairs(cache) do cache[k] = nil end

  local allItemsCached = true

  for bag, slot, itemId in B.Container:IterateSlots() do
    if itemId then
      local item = BagItemsCache:CreateItem(bag, slot)
      if item then
        setCachedItem(bag, slot, item)
      else
        allItemsCached = false
      end
    end
  end

  -- Try again on the next tick.
  if not allItemsCached then markDirty() end

  EventManager:Fire(E.BagsUpdated, allItemsCached)
end

-- ============================================================================
-- Events
-- ============================================================================

-- Register events to trigger cache updates.
EventManager:Once(E.Wow.PlayerLogin, function()
  markDirty()

  -- Starts a burst.
  EventManager:On(E.Wow.BagUpdate, function()
    burstStartTime = burstStartTime or B.Utils:GetTime()
    markDirty()
  end)

  -- Ends the burst.
  EventManager:On(E.Wow.BagUpdateDelayed, function()
    burstStartTime = nil
    markDirty()
  end)

  EventManager:On(E.Wow.EquipmentSetsChanged, markDirty)

  -- Update the cache at most once per tick, and not during a burst.
  TickerManager:NewTicker(BagItemsCache.UPDATE_TICK_SECONDS, function()
    if isDirty and not isBurstActive() then updateCache() end
  end)

  -- A refund window can expire with no bag event to catch it, so poll for
  -- that and fire `BagsUpdated` when it happens.
  TickerManager:NewTicker(BagItemsCache.REFUND_POLL_SECONDS, function()
    local now = B.Utils:GetTime()
    local anyExpired = false

    for _, item in pairs(cache) do
      if item.refundExpirationTime and item.refundExpirationTime <= now then
        item.refundExpirationTime = nil
        anyExpired = true
      end
    end

    if anyExpired then EventManager:Fire(E.BagsUpdated, true) end
  end)
end)

-- ============================================================================
-- BagItemsCache
-- ============================================================================

--- Creates or updates an array with all cached items.
--- @param items? BagItem[]
--- @return BagItem[] items
function BagItemsCache:GetItems(items)
  if type(items) ~= "table" then
    items = {}
  else
    for k in pairs(items) do items[k] = nil end
  end

  -- Add cached items.
  for _, item in pairs(cache) do
    items[#items + 1] = item
  end

  return items
end

--- Returns a cached `BagItem` for the given `bag` and `slot`, if available.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
function BagItemsCache:GetItem(bag, slot)
  return getCachedItem(bag, slot)
end

--- Returns an integer that identifies the given `bag` and `slot`, for use as a table key.
--- @param bag integer
--- @param slot integer
--- @return integer key
function BagItemsCache:GetSlotKey(bag, slot)
  return bag * 1000 + slot
end

--- Creates a new `BagItem` for the given `bag` and `slot`, or returns `nil` if the slot is empty or its item data is
--- not loaded.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
function BagItemsCache:CreateItem(bag, slot)
  --- @class BagItem : BagItemInfo
  --- @field reason? string
  local item = B.Container:GetItemInfo(bag, slot)
  if item == nil then return nil end

  -- Item info.
  local name, baseItemLevel, invType, price, classId, subclassId = B.Item:GetInfo(item.link)
  if name == nil then
    name, baseItemLevel, invType, price, classId, subclassId = B.Item:GetInfo(item.id)
    if name == nil then return nil end
  end

  item.name = name
  item.baseItemLevel = baseItemLevel
  item.invType = invType
  item.price = price
  item.classId = classId
  item.subclassId = subclassId
  item.isEquipmentSet = EquipmentSetsCache:IsBagSlotCached(bag, slot)

  local refundSeconds = B.Container:GetRefundSeconds(bag, slot)
  item.refundExpirationTime = refundSeconds and refundSeconds > 0 and (B.Utils:GetTime() + refundSeconds) or nil

  return item
end

-- BagItemsCache:GetFreshItem()
do
  --- @type number?
  local lastRefreshTime

  --- Creates a new `BagItem` for the given `bag` and `slot`.
  --- @param bag integer
  --- @param slot integer
  --- @return BagItem? item
  function BagItemsCache:GetFreshItem(bag, slot)
    local now = B.Utils:GetTime()

    -- Refresh equipment sets once per frame.
    if now ~= lastRefreshTime then
      lastRefreshTime = now
      EquipmentSetsCache:Refresh()
    end

    return self:CreateItem(bag, slot)
  end
end
