--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Seconds per frame in the fake game.
local FRAME_SECONDS = 0.05

--- Enough time for the cache to update after a bag event, however it schedules the update.
local UPDATE_SECONDS = 0.2

--- Enough time for the cache to try again after an item's data was not loaded.
local RETRY_SECONDS = 0.5

--- The seconds left to refund an item in the refund tests.
local REFUND_SECONDS = 30

--- Enough time for the refund poll to run once.
local REFUND_POLL_SECONDS = 1.5

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
    unloadedItemIds = {}
  }

  -- `Blizzard`, reading from `game.slots`.
  local Blizzard = { Container = {}, Item = {}, Utils = {} }

  local ContainerSpy = Mocks:CreateSpy(Blizzard.Container)

  ContainerSpy:Stub("IterateSlots"):Invokes(function()
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

  game.E = Context:GetModule("Events")
  game.EventManager = EventManager

  return Context:GetModule("BagItemsCache"), game
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
  game.Advance(UPDATE_SECONDS)

  assert(Matchers:IsDeepEqual(getSortedIds(BagItemsCache:GetItems()), { 100, 200 }))
end

-- Test: fills and returns the array it is given, replacing what it held.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

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
  game.Advance(UPDATE_SECONDS)

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
  game.Advance(UPDATE_SECONDS)

  assert(BagItemsCache:GetItem(0, 1) == nil)
  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: returns an item once its data loads, without another bag event.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(RETRY_SECONDS)
  assert(BagItemsCache:GetItem(0, 1) == nil)

  game.unloadedItemIds[100] = nil
  game.Advance(RETRY_SECONDS)

  assert(BagItemsCache:GetItem(0, 1).id == 100)
end

-- ============================================================================
-- Tests - BagsUpdated
-- ============================================================================

-- Test: fires once after the cache updates, with `true` when every item's data is loaded.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(allItemsCached)
    payloads[#payloads + 1] = allItemsCached
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  assert(Matchers:IsDeepEqual(payloads, { true }))
end

-- Test: fires with `false` while an item's data is not loaded.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }
  game.unloadedItemIds[100] = true

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(allItemsCached)
    payloads[#payloads + 1] = allItemsCached
  end)

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  assert(payloads[1] == false)
end

-- ============================================================================
-- Tests - Bag events
-- ============================================================================

-- Test: BAG_UPDATE makes the cache catch up with the bags.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.BagUpdate)
  game.Advance(UPDATE_SECONDS)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: BAG_UPDATE_DELAYED makes the cache catch up with the bags.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.Advance(UPDATE_SECONDS)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: EQUIPMENT_SETS_CHANGED makes the cache catch up with the bags.
do
  local BagItemsCache, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  game.slots[2] = { bag = 0, slot = 2, itemId = 200 }
  game.Fire(game.E.Wow.EquipmentSetsChanged)
  game.Advance(UPDATE_SECONDS)

  assert(BagItemsCache:GetItem(0, 2).id == 200)
end

-- Test: events that arrive together cause one update.
do
  local _, game = setupContext()
  game.slots = { { bag = 0, slot = 1, itemId = 100 } }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(UPDATE_SECONDS)

  local updates = 0
  game.EventManager:On(game.E.BagsUpdated, function() updates = updates + 1 end)

  game.Fire(game.E.Wow.BagUpdate)
  game.Fire(game.E.Wow.BagUpdate)
  game.Fire(game.E.Wow.BagUpdateDelayed)
  game.Fire(game.E.Wow.EquipmentSetsChanged)
  game.Advance(UPDATE_SECONDS)

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
  game.Advance(UPDATE_SECONDS)
  assert(BagItemsCache:GetItem(0, 1).refundExpirationTime ~= nil)

  local payloads = {}
  game.EventManager:On(game.E.BagsUpdated, function(allItemsCached)
    payloads[#payloads + 1] = allItemsCached
  end)

  game.Advance(REFUND_SECONDS + REFUND_POLL_SECONDS)

  assert(BagItemsCache:GetItem(0, 1).refundExpirationTime == nil)
  assert(Matchers:IsDeepEqual(payloads, { true }))
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
