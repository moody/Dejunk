local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local E = Addon:GetModule("Events")
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")
local EventManager = Addon:GetModule("EventManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class BagItemsCache
local BagItemsCache = Addon:GetModule("BagItemsCache")

--- An integer that identifies a bag slot, from `BagItemsCache:GetSlotKey()`.
--- @alias SlotKey integer

--- Seconds between checks for whether the cache needs updating.
--- @type number
BagItemsCache.UPDATE_TICK_SECONDS = 0.1

--- Seconds that a burst of `BAG_UPDATE` events can hold back an update.
--- @type number
BagItemsCache.BURST_MAX_SECONDS = 2

--- Seconds to retry a slot whose item data is not loaded before giving up on it.
--- @type number
BagItemsCache.PENDING_DEADLINE_SECONDS = 5

-- ============================================================================
-- State
-- ============================================================================

-- --------------------------------------
-- Items
-- --------------------------------------

--- @type table<SlotKey, BagItem>
local cache = {}

--- The time to stop retrying each slot whose item data is not loaded, by slot key.
--- @type table<SlotKey, number>
local pending = {}

--- Increases whenever the cache changes.
local version = 0

-- --------------------------------------
-- Update timing
-- --------------------------------------

--- Whether the next tick updates the cache. True until the first update.
local isDirty = true

--- The time the current burst of `BAG_UPDATE` events started, or `nil` if there is none.
--- @type number?
local burstStartTime

-- --------------------------------------
-- Waiters
-- --------------------------------------

--- @class BagItemsCacheWaiter
--- @field callback fun(isSettled: boolean)
--- @field deadline number The time to call back even if the cache is not settled.

--- The callers of `WhenSettled()` that are still waiting.
--- @type BagItemsCacheWaiter[]
local queuedWaiters = {}

--- The waiters that `processWaiters()` is about to call.
--- @type BagItemsCacheWaiter[]
local readyWaiters = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Marks the cache to be updated on the next tick.
local function markDirty()
  isDirty = true
end

--- Returns `true` if a burst of `BAG_UPDATE` events is holding back updates. A burst ends after `BURST_MAX_SECONDS`
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

--- Increases the version and fires the `BagsUpdated` event.
--- @param noItemsPending boolean
local function fireBagsUpdated(noItemsPending)
  version = version + 1
  EventManager:Fire(E.BagsUpdated, noItemsPending)
end

--- Updates the item cache and fires the `BagsUpdated` event.
local function updateCache()
  isDirty = false
  burstStartTime = nil

  EquipmentSetsCache:Refresh()

  for k in pairs(cache) do cache[k] = nil end
  for k in pairs(pending) do pending[k] = nil end

  for bag, slot, itemId in B.Container:IterateSlots() do
    if itemId then
      local item = BagItemsCache:CreateItem(bag, slot)
      if item then
        setCachedItem(bag, slot, item)
      else
        pending[BagItemsCache:GetSlotKey(bag, slot)] = B.Utils:GetTime() + BagItemsCache.PENDING_DEADLINE_SECONDS
      end
    end
  end

  fireBagsUpdated(next(pending) == nil)
end

--- Retries the pending slots, and fires `BagsUpdated` if any were cached or dropped.
local function updatePending()
  local anyResolved = false
  local now = B.Utils:GetTime()

  for key, deadline in pairs(pending) do
    local bag, slot = BagItemsCache:GetSlotFromKey(key)
    local item = BagItemsCache:CreateItem(bag, slot)
    if item then setCachedItem(bag, slot, item) end

    if item or now >= deadline then
      pending[key] = nil
      anyResolved = true
    end
  end

  if anyResolved then fireBagsUpdated(next(pending) == nil) end
end

--- Calls the waiters when the cache is settled or their deadline has passed, in the order they were added.
local function processWaiters()
  if #queuedWaiters == 0 then return end

  local now = B.Utils:GetTime()
  local isSettled = BagItemsCache:IsSettled()

  -- Collect first, so callbacks can add waiters.
  for i = #queuedWaiters, 1, -1 do
    if isSettled or now >= queuedWaiters[i].deadline then
      readyWaiters[#readyWaiters + 1] = table.remove(queuedWaiters, i)
    end
  end

  -- Collected newest first, so removing from the end calls the oldest first.
  for _ = 1, #readyWaiters do
    table.remove(readyWaiters).callback(isSettled)
  end
end

-- ============================================================================
-- Events
-- ============================================================================

-- Register events to trigger cache updates.
EventManager:Once(E.Wow.PlayerLogin, function()
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

  -- Update the cache at most once per tick, and not during a burst. With nothing to update, retry the pending slots.
  -- Waiters are checked every tick, even during a burst.
  TickerManager:NewTicker(BagItemsCache.UPDATE_TICK_SECONDS, function()
    if not isBurstActive() then
      if isDirty then
        updateCache()
      elseif next(pending) then
        updatePending()
      end
    end

    processWaiters()
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

--- Returns a number that increases whenever the cache changes.
--- @return integer version
function BagItemsCache:GetVersion()
  return version
end

--- Returns `true` if the cache is up to date and no slot is waiting for item data.
--- @return boolean
function BagItemsCache:IsSettled()
  return not isDirty and next(pending) == nil
end

--- Calls `callback` on the next tick that finds the cache settled, or when `maxWait` runs out.
--- @param maxWait number The seconds to wait for the cache to settle.
--- @param callback fun(isSettled: boolean) Receives `false` if `maxWait` ran out first.
--- @param force? boolean Ends a burst in progress, so the cache can update right away.
function BagItemsCache:WhenSettled(maxWait, callback, force)
  if force then burstStartTime = nil end
  queuedWaiters[#queuedWaiters + 1] = { callback = callback, deadline = B.Utils:GetTime() + maxWait }
end

--- Returns an integer that identifies the given `bag` and `slot`, for use as a table key.
--- @param bag integer
--- @param slot integer
--- @return SlotKey key
function BagItemsCache:GetSlotKey(bag, slot)
  return bag * 1000 + slot
end

--- Returns the bag and slot that the given `key` from `GetSlotKey()` identifies.
--- @param key SlotKey
--- @return integer bag, integer slot
function BagItemsCache:GetSlotFromKey(key)
  local slot = key % 1000
  return (key - slot) / 1000, slot
end

--- Creates a new `BagItem` for the given `bag` and `slot`, or returns `nil` if the slot is empty or its item data is
--- not loaded.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
function BagItemsCache:CreateItem(bag, slot)
  --- @class BagItem : BagItemInfo
  --- @field refundExpirationTime? number
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
