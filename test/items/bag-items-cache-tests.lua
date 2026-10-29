--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Seconds per frame in the fake game.
local FRAME_SECONDS = 0.05

--- The seconds between the `BAG_UPDATE` events of a burst.
local BAG_UPDATE_GAP_SECONDS = 0.25

--- The seconds left to refund an item in the refund tests.
local REFUND_SECONDS = 30

--- Returns `BagItemsCache` and a fake game, from a new context. The cache sees a fake `Blizzard` that reads
--- `game.slots`, and the real `EventManager` and `TickerManager`, which the game drives with events and time.
--- @return BagItemsCache BagItemsCache
--- @return table game
local function setupContext()
  local Context = Harness:NewContext()

  local game = {
    --- Every slot in the bags, in order. A slot with no `itemId` is empty.
    --- @type { bag: integer, slot: integer, itemId: integer? }[]
    slots = {},

    --- The time that `Blizzard.Utils:GetTime()` returns.
    time = 0,

    --- The seconds left to refund every item, or `nil` if it has no refund window.
    --- @type number?
    refundSeconds = nil,

    --- The IDs of the items whose data is not loaded. `Blizzard.Item:GetInfo()` returns nothing for them.
    --- @type table<integer, true>
    unloadedItemIds = {},

    --- The number of times the cache has scanned every slot.
    scanCount = 0
  }

  -- `Blizzard`, reading from `game.slots`.
  local Blizzard = { Container = {}, Item = {}, Utils = {} }

  local ContainerSpy = Mocks:CreateSpy(Blizzard.Container)

  ContainerSpy:Stub("IterateSlots"):Invokes(function()
    game.scanCount = game.scanCount + 1
    local index = 0

    return function()
      index = index + 1
      local entry = game.slots[index]
      if entry then return entry.bag, entry.slot, entry.itemId end
    end
  end)

  ContainerSpy:Stub("GetItemInfo"):Invokes(function(_, bag, slot)
    for _, entry in ipairs(game.slots) do
      if entry.bag == bag and entry.slot == slot and entry.itemId then
        return { bag = bag, slot = slot, id = entry.itemId, link = "item:" .. entry.itemId }
      end
    end
  end)

  ContainerSpy:Stub("GetRefundSeconds"):Invokes(function() return game.refundSeconds end)

  Mocks:CreateSpy(Blizzard.Item):Stub("GetInfo"):Invokes(function(_, item)
    local itemId = type(item) == "number" and item or tonumber(tostring(item):match("%d+"))
    if game.unloadedItemIds[itemId] then return end

    return "Name", 10, "INVTYPE_HEAD", 100, 2, 1
  end)
  Mocks:CreateSpy(Blizzard.Utils):Stub("GetTime"):Invokes(function() return game.time end)

  Context:SetModule("Blizzard", Blizzard)

  local EquipmentSetsCache = {}
  local EquipmentSetsCacheSpy = Mocks:CreateSpy(EquipmentSetsCache)
  EquipmentSetsCacheSpy:Stub("Refresh")
  EquipmentSetsCacheSpy:Stub("IsBagSlotCached"):Returns(false)
  Context:SetModule("EquipmentSetsCache", EquipmentSetsCache)

  -- The real event and ticker managers, each with a frame that the test drives.
  local tickerFrame = Mocks:CreateFrame()

  Context:SetGlobal("CreateFrame", function() return Mocks:CreateFrame() end)
  Context:Load("src/events/events.lua")
  Context:Load("src/events/event-manager.lua")

  Context:SetGlobal("CreateFrame", function() return tickerFrame end)
  Context:Load("src/utils/ticker-manager.lua")

  Context:Load("src/items/bag-items-cache.lua")

  local BagItemsCache = Context:GetModule("BagItemsCache")
  local EventManager = Context:GetModule("EventManager")

  --- Fires a game event, as the game does.
  --- @param event string
  function game.Fire(event)
    EventManager:Fire(event)
  end

  --- Moves the game's time forward a frame at a time, running the tickers that are due.
  --- @param seconds number
  function game.Advance(seconds)
    local remaining = seconds

    while remaining > 0 do
      local elapsed = math.min(remaining, FRAME_SECONDS)
      remaining = remaining - elapsed
      game.time = game.time + elapsed
      tickerFrame._test.scripts.OnUpdate(tickerFrame, elapsed)
    end
  end

  --- Moves the game's time forward by `count` update ticks of the cache, plus a frame so the last tick has run.
  --- @param count integer
  function game.AdvanceTicks(count)
    game.Advance(count * BagItemsCache.UPDATE_TICK_SECONDS + FRAME_SECONDS)
  end

  game.E = Context:GetModule("Events")
  game.EventManager = EventManager

  return BagItemsCache, game
end

--- Returns the IDs of the given items, sorted.
--- @param items BagItem[]
--- @return integer[]
local function getSortedIds(items)
  local ids = {}
  for _, item in ipairs(items) do ids[#ids + 1] = item.id end
  table.sort(ids)
  return ids
end

--- Fires `BAG_UPDATE` every `BAG_UPDATE_GAP_SECONDS` until `seconds` have passed.
--- @param game table
--- @param seconds number
local function fireBagUpdatesFor(game, seconds)
  local elapsed = 0

  while elapsed < seconds do
    game.Fire(game.E.Wow.BagUpdate)
    game.Advance(BAG_UPDATE_GAP_SECONDS)
    elapsed = elapsed + BAG_UPDATE_GAP_SECONDS
  end
end

-- ============================================================================
-- Tests - BagItemsCache:GetItems()
-- ============================================================================

-- Test: returns an item for each occupied slot after login.
do
  local BagItemsCache, game = setupContext()
  game.slots = {
    { bag = 0, slot = 1, itemId = 100 },
    { bag = 0, slot = 2 },
    { bag = 1, slot = 1, itemId = 200 }
  }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(Matchers:IsDeepEqual(getSortedIds(BagItemsCache:GetItems()), { 100, 200 }))
end

-- Test: fills and returns the array it is given, replacing what it held.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local given = { "stale", "stale" }
  local items = BagItemsCache:GetItems(given)

  assert(items == given)
  assert(#items == 1)
  assert(items[1].id == 100)
end

-- ============================================================================
-- Tests - BagItemsCache:GetItem()
-- ============================================================================

-- Test: returns the item cached for a slot, and nothing for an empty slot.
do
  local BagItemsCache, game = setupContext()
  game.slots = {
    { bag = 0, slot = 1, itemId = 100 },
    { bag = 0, slot = 2 },
    { bag = 1, slot = 1, itemId = 200 }
  }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(1, 1).id == 200)
  assert(BagItemsCache:GetItem(0, 2) == nil)
end

-- Test: leaves out an item whose data is not loaded.
do
  local BagItemsCache, game = setupContext()
  game.slots = {
    { bag = 0, slot = 1, itemId = 100 },
    { bag = 0, slot = 2, itemId = 200 }
  }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 1) == nil)
  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: returns an item once its data loads, without another bag event.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  assert(BagItemsCache:GetItem(0, 1) == nil)

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 1).id == 100)
end

-- Test: retries a slot whose item data was not loaded without scanning every slot again.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)

  assert(game.scanCount == 1)
end

-- Test: keeps retrying a slot until its deadline.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(BagItemsCache.PENDING_DEADLINE_SECONDS - BagItemsCache.UPDATE_TICK_SECONDS)

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 1).id == 100)
end

-- Test: gives up on a slot whose item data does not load by its deadline, and fires `BagsUpdated` with `true`.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  game.Advance(BagItemsCache.PENDING_DEADLINE_SECONDS)
  game.AdvanceTicks(1)

  assert(Matchers:IsDeepEqual(payloads, { false, true }))
  assert(BagItemsCache:GetItem(0, 1) == nil)
end

-- Test: does not retry a slot after its deadline, so an item that loads later waits for the next update.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  game.Advance(BagItemsCache.PENDING_DEADLINE_SECONDS)
  game.AdvanceTicks(1)

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)
  assert(BagItemsCache:GetItem(0, 1) == nil)

  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 1).id == 100)
end

-- ============================================================================
-- Tests - BagsUpdated
-- ============================================================================

-- Test: fires once after the cache updates, with `true` when no item is pending.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(Matchers:IsDeepEqual(payloads, { true }))
end

-- Test: fires with `false` while an item's data is not loaded.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(payloads[1] == false)
end

-- Test: fires again with `true` once the pending item's data loads.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)

  assert(Matchers:IsDeepEqual(payloads, { false, true }))
end

-- Test: an update leaves nothing pending for a slot that has since been emptied.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.slots = { { bag = 0, slot = 1 } }
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.AdvanceTicks(1)

  assert(Matchers:IsDeepEqual(payloads, { true }))
end

-- ============================================================================
-- Tests - Bag events
-- ============================================================================

-- Test: BAG_UPDATE makes the cache catch up with the bags, even if BAG_UPDATE_DELAYED does not arrive.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.BagUpdate)
  game.Advance(BagItemsCache.BURST_MAX_SECONDS)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: BAG_UPDATE_DELAYED makes the cache catch up with the bags.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: EQUIPMENT_SETS_CHANGED makes the cache catch up with the bags.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.EquipmentSetsChanged)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: events that arrive together cause one update.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local updates = 0
  game.EventManager:On(game.E.BagsUpdated, function() updates = updates + 1 end)

  game.Fire(game.E.Wow.BagUpdate)
  game.Fire(game.E.Wow.BagUpdate)
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.Fire(game.E.Wow.EquipmentSetsChanged)
  game.AdvanceTicks(1)

  assert(updates == 1)
end

-- Test: holds back updates while BAG_UPDATE events keep arriving.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local updates = 0
  game.EventManager:On(game.E.BagsUpdated, function() updates = updates + 1 end)

  fireBagUpdatesFor(game, BagItemsCache.BURST_MAX_SECONDS / 2)

  assert(updates == 0)
end

-- Test: holds back retries of pending slots while BAG_UPDATE events keep arriving.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  game.unloadedItemIds[100] = nil
  fireBagUpdatesFor(game, BagItemsCache.BURST_MAX_SECONDS / 2)
  assert(BagItemsCache:GetItem(0, 1) == nil)

  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetItem(0, 1).id == 100)
end

-- Test: updates once after BAG_UPDATE_DELAYED ends a burst of BAG_UPDATE events.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local updates = 0
  game.EventManager:On(game.E.BagsUpdated, function() updates = updates + 1 end)

  fireBagUpdatesFor(game, BagItemsCache.BURST_MAX_SECONDS / 2)
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.AdvanceTicks(1)

  assert(updates == 1)
end

-- Test: updates once a burst reaches its maximum age, however many BAG_UPDATE events keep arriving.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  local updates = 0
  game.EventManager:On(game.E.BagsUpdated, function() updates = updates + 1 end)

  fireBagUpdatesFor(game, BagItemsCache.BURST_MAX_SECONDS * 1.5)

  assert(updates == 1)
end

-- ============================================================================
-- Tests - Refund poll
-- ============================================================================

-- Test: clears `refundExpirationTime` when the refund window ends, and fires `BagsUpdated` with `true`.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.time = 100
  game.refundSeconds = REFUND_SECONDS

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  assert(BagItemsCache:GetItem(0, 1).refundExpirationTime ~= nil)

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Advance(REFUND_SECONDS + BagItemsCache.REFUND_POLL_SECONDS * 2)

  assert(BagItemsCache:GetItem(0, 1).refundExpirationTime == nil)
  assert(Matchers:IsDeepEqual(payloads, { true }))
end

-- Test: fires `BagsUpdated` with `false` when the refund window ends while another slot is pending.
do
  local BagItemsCache, game = setupContext()
  game.slots = {
    { bag = 0, slot = 1, itemId = 100 },
    { bag = 0, slot = 2, itemId = 200 }
  }
  game.unloadedItemIds[200] = true
  game.refundSeconds = BagItemsCache.PENDING_DEADLINE_SECONDS / 2

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(noItemsPending)
    payloads[#payloads + 1] = noItemsPending
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  game.Advance(game.refundSeconds + BagItemsCache.REFUND_POLL_SECONDS * 2)

  assert(Matchers:IsDeepEqual(payloads, { false, false }))
end

-- ============================================================================
-- Tests - BagItemsCache:GetVersion()
-- ============================================================================

-- Test: increases when the cache updates.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  local version = BagItemsCache:GetVersion()

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetVersion() > version)
end

-- Test: stays the same while nothing changes.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  local version = BagItemsCache:GetVersion()

  game.AdvanceTicks(10)

  assert(BagItemsCache:GetVersion() == version)
end

-- Test: increases when a refund window ends.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.refundSeconds = REFUND_SECONDS

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  local version = BagItemsCache:GetVersion()

  game.Advance(REFUND_SECONDS + BagItemsCache.REFUND_POLL_SECONDS * 2)

  assert(BagItemsCache:GetVersion() > version)
end

-- Test: increases when a pending slot's item data loads.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  local version = BagItemsCache:GetVersion()

  game.unloadedItemIds[100] = nil
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetVersion() > version)
end

-- Test: increases when a pending slot is dropped at its deadline.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.AdvanceTicks(1)
  local version = BagItemsCache:GetVersion()

  game.Advance(BagItemsCache.PENDING_DEADLINE_SECONDS)
  game.AdvanceTicks(1)

  assert(BagItemsCache:GetVersion() > version)
end

-- ============================================================================
-- Tests - BagItemsCache:GetSlotKey()
-- ============================================================================

-- Test: returns a different key for each bag and slot, including negative bags.
do
  local BagItemsCache = setupContext()
  local keys = {}
  local count = 0

  for bag = -2, 12 do
    for slot = 1, 98 do
      keys[BagItemsCache:GetSlotKey(bag, slot)] = true
      count = count + 1
    end
  end

  local uniqueCount = 0
  for _ in pairs(keys) do uniqueCount = uniqueCount + 1 end

  assert(uniqueCount == count)
end

-- ============================================================================
-- Tests - BagItemsCache:GetSlotFromKey()
-- ============================================================================

-- Test: returns the bag and slot that a slot key was made from, including negative bags.
do
  local BagItemsCache = setupContext()
  local slots = { { 0, 1 }, { 5, 98 }, { -1, 28 }, { -2, 32 } }

  for _, entry in ipairs(slots) do
    local key = BagItemsCache:GetSlotKey(entry[1], entry[2])
    local bag, slot = BagItemsCache:GetSlotFromKey(key)
    assert(bag == entry[1])
    assert(slot == entry[2])
  end
end

-- ============================================================================
-- Tests - BagItemsCache:CreateItem()
-- ============================================================================

-- Test: builds the item from the slot and the item's info.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 2, slot = 3, itemId = 300 } }

  local item = BagItemsCache:CreateItem(2, 3)

  assert(Matchers:IsDeepEqual(item, {
    bag = 2,
    slot = 3,
    id = 300,
    link = "item:300",
    name = "Name",
    baseItemLevel = 10,
    invType = "INVTYPE_HEAD",
    price = 100,
    classId = 2,
    subclassId = 1,
    isEquipmentSet = false
  }))
end

-- Test: sets `refundExpirationTime` from the seconds left to refund.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.time = 100
  game.refundSeconds = 30

  assert(BagItemsCache:CreateItem(0, 1).refundExpirationTime == 130)
end
