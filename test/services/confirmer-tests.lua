--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")
local TestGame = require("test/test-game")

-- ============================================================================
-- Setup
-- ============================================================================

--- Seconds that run the Confirmer's ticker once, well before the timeout.
local CONFIRM_SECONDS = 0.1

--- Seconds after which an unconfirmed attempt counts as one that may not have worked.
local TIMEOUT_SECONDS = 5

--- Returns a test game, the spies of the `Addon` print methods, and a function that takes an item out of the bags,
--- from a new context where `Confirmer` is loaded. Every item is in the bags until it is taken out.
--- @return TestGameInstance Game
--- @return MockSpy AddonSpy Records the `Addon:Print()` and `Addon:PrintVerbose()` calls.
--- @return fun(item: BagItem) removeFromBags
local function setupContext()
  local Context = Harness:NewContext()
  local Game = TestGame:New(Context)

  local AddonSpy = Mocks:CreateSpy(Context.Addon)
  AddonSpy:Stub("Print")
  AddonSpy:Stub("PrintVerbose")

  local removedItems = {}
  local Items = {}
  Mocks:CreateSpy(Items):Stub("IsItemStillInBags"):Invokes(function(_, item) return not removedItems[item] end)

  --- Takes the item out of the bags, as a sale does once the game confirms it.
  --- @param item BagItem
  local function removeFromBags(item)
    removedItems[item] = true
  end

  Context:SetModule("Items", Items)
  Context:SetModule("Locale", {
    FAILED_TO_SELL_ITEM = "FAILED_TO_SELL_ITEM %s",
    ITEMS_SOLD = "ITEMS_SOLD %s",
    MAY_NOT_HAVE_SOLD_ITEM = "MAY_NOT_HAVE_SOLD_ITEM %s",
    PROFIT = "PROFIT %s",
    SOLD_ITEM = "SOLD_ITEM %s"
  })
  Context:SetGlobal("GetCoinTextureString", function(copper) return copper .. "c" end)
  Context:Load("src/services/confirmer.lua")

  return Game, AddonSpy, removeFromBags
end

--- Returns an item that is a stack of one, with the given link and price.
--- @param link string
--- @param price integer
--- @return BagItem
local function createItem(link, price)
  return { bag = 0, slot = 1, link = link, quantity = 1, price = price }
end

-- ============================================================================
-- Tests - Confirmer, items sold during a run
-- ============================================================================

-- Test: an item sold during a run is printed with `PrintVerbose()`, not `Print()`.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local item = createItem("link", 10)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, item, "RUN")
  removeFromBags(item)
  Game:Advance(CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("PrintVerbose").calls, { { "SOLD_ITEM link" } }))
  assert(#AddonSpy:GetStub("Print").calls == 0)
end

-- Test: the summary prints the number of items sold and the profit once the run has stopped.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local itemA = createItem("linkA", 10)
  local itemB = createItem("linkB", 20)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, itemA, "RUN")
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, itemB, "RUN")
  removeFromBags(itemA)
  removeFromBags(itemB)
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("Print").calls, { { "ITEMS_SOLD 2" }, { "PROFIT 30c" } }))
end

-- Test: the summary waits until every item sold in the run has left the bags.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local itemA = createItem("linkA", 10)
  local itemB = createItem("linkB", 20)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, itemA, "RUN")
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, itemB, "RUN")
  removeFromBags(itemA)
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(CONFIRM_SECONDS)

  assert(#AddonSpy:GetStub("Print").calls == 0)

  removeFromBags(itemB)
  Game:Advance(CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("Print").calls, { { "ITEMS_SOLD 2" }, { "PROFIT 30c" } }))
end

-- Test: an item that failed to sell is reported and is not counted in the summary.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local soldItem = createItem("sold", 10)
  local failedItem = createItem("failed", 20)
  failedItem.slot = 2

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, soldItem, "RUN")
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, failedItem, "RUN")
  removeFromBags(soldItem)
  Game:Fire(Game.E.Wow.ItemUnlocked, failedItem.bag, failedItem.slot)
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("Print").calls, {
    { "FAILED_TO_SELL_ITEM failed" },
    { "ITEMS_SOLD 1" },
    { "PROFIT 10c" }
  }))
end

-- Test: an item that was not confirmed in time is reported and is not counted in the summary.
do
  local Game, AddonSpy = setupContext()
  local item = createItem("link", 10)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, item, "RUN")
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(TIMEOUT_SECONDS + CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("Print").calls, { { "MAY_NOT_HAVE_SOLD_ITEM link" } }))
end

-- Test: a new run counts only its own items.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local firstItem = createItem("first", 10)
  local secondItem = createItem("second", 20)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, firstItem, "RUN")
  removeFromBags(firstItem)
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(CONFIRM_SECONDS)

  Game.EventManager:Fire(Game.E.SellerStarted)
  Game.EventManager:Fire(Game.E.AttemptedToSellItem, secondItem, "RUN")
  removeFromBags(secondItem)
  Game.EventManager:Fire(Game.E.SellerStopped)
  Game:Advance(CONFIRM_SECONDS)

  local calls = AddonSpy:GetStub("Print").calls
  assert(Matchers:IsDeepEqual({ calls[3], calls[4] }, { { "ITEMS_SOLD 1" }, { "PROFIT 20c" } }))
end

-- ============================================================================
-- Tests - Confirmer, items sold on their own
-- ============================================================================

-- Test: an item sold outside a run is printed with `Print()`, and there is no summary.
do
  local Game, AddonSpy, removeFromBags = setupContext()
  local item = createItem("link", 10)

  Game.EventManager:Fire(Game.E.AttemptedToSellItem, item, "MANUAL")
  removeFromBags(item)
  Game:Advance(CONFIRM_SECONDS)

  assert(Matchers:IsDeepEqual(AddonSpy:GetStub("Print").calls, { { "SOLD_ITEM link" } }))
  assert(#AddonSpy:GetStub("PrintVerbose").calls == 0)
end
