--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `BagItemsCache` and a fake game, from a new context. The cache uses a fake `Blizzard` that reads the bags
--- from `game.slots`, and the real `EventManager` and `TickerManager`, which the fake game drives with events and time.
--- @return BagItemsCache BagItemsCache
--- @return table game
local function setupContext()
  local Context = Harness:NewContext()

  local game = {
    --- Every slot in the bags, in order. A slot with no `itemId` is empty.
    --- @type { bag: integer, slot: integer, itemId: integer? }[]
    slots = {},

    --- The time that `Blizzard.Utils:GetTime()` returns.
    time = 0
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

  ContainerSpy:Stub("GetRefundSeconds"):Returns(nil)

  Mocks:CreateSpy(Blizzard.Item):Stub("GetInfo"):Returns("Name", 10, "INVTYPE_HEAD", 100, 2, 1)
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

  --- Moves the game's time forward and runs the tickers that are due.
  --- @param seconds number
  function game.Advance(seconds)
    game.time = game.time + seconds
    tickerFrame._test.scripts.OnUpdate(tickerFrame, seconds)
  end

  game.E = Context:GetModule("Events")

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

-- Test: returns an item for each occupied slot once the cache has updated after login.
do
  local BagItemsCache, game = setupContext()
  game.slots = {
    { bag = 0, slot = 1, itemId = 100 },
    { bag = 0, slot = 2 },
    { bag = 1, slot = 1, itemId = 200 }
  }

  game.Fire(game.E.Wow.PlayerLogin)
  game.Advance(0.2)

  assert(Matchers:IsDeepEqual(getSortedIds(BagItemsCache:GetItems()), { 100, 200 }))
end
