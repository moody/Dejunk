local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local E = Addon:GetModule("Events")
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")
local EventManager = Addon:GetModule("EventManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class BagItemsCache
local BagItemsCache = Addon:GetModule("BagItemsCache")

--- @type table<integer, BagItem>
local cache = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

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

  EventManager:Fire(E.BagsUpdated, allItemsCached)
end

-- ============================================================================
-- Events
-- ============================================================================

-- Register events to trigger cache updates.
EventManager:Once(E.Wow.PlayerLogin, function()
  local debounce = TickerManager:NewDebouncer(0.1, updateCache)
  debounce()

  EventManager:On(E.Wow.BagUpdate, debounce)
  EventManager:On(E.Wow.BagUpdateDelayed, debounce)
  EventManager:On(E.Wow.EquipmentSetsChanged, debounce)
  EventManager:On(E.BagsUpdated, function(allItemsCached)
    if not allItemsCached then TickerManager:After(0.01, debounce) end
  end)

  -- A refund window can expire with no bag event to catch it, so poll for
  -- that and fire `BagsUpdated` when it happens.
  TickerManager:NewTicker(1, function()
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
