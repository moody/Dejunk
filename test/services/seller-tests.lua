--- @diagnostic disable: undefined-global

local TestGame = require("test/test-game")
local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- The seconds between sales.
local SALE_SECONDS = 0.2

--- Returns `Seller`, a test game, and the spies of the modules it uses, from a new context. The merchant is open,
--- the bag items cache settles at once, Safe Sell and Auto Sell are off, and nothing is sellable. A test changes a
--- stub with `GetStub()`.
--- @return Seller Seller
--- @return TestGameInstance Game
--- @return SellerTestSpies spies
local function setupContext()
  local Context = Harness:NewContext()
  Context.Addon.IS_VANILLA = false
  Context.Addon.IS_TBC = false

  local Game = TestGame:New(Context)

  -- The `Addon` helpers that `Seller` calls.
  local AddonSpy = Mocks:CreateSpy(Context.Addon)
  AddonSpy:Stub("GetLatency"):Returns(SALE_SECONDS)
  AddonSpy:Stub("Print")

  Mocks:CreateSpy(Context:GetModule("Confirmer")):Stub("IsBusy"):Returns(false)

  -- What `Seller` calls on the bag items cache. Only `WhenSettled()` is stubbed.
  Context:Load("src/items/bag-items-cache.lua")
  local BagItemsCache = Context:GetModule("BagItemsCache")
  local BagItemsCacheSpy = Mocks:CreateSpy(BagItemsCache)
  BagItemsCacheSpy:Stub("WhenSettled"):Invokes(function(_, _, callback) callback(true) end)

  local MerchantFrame = {}
  local MerchantFrameSpy = Mocks:CreateSpy(MerchantFrame)
  MerchantFrameSpy:Stub("IsShown"):Returns(true)
  Context:SetGlobal("MerchantFrame", MerchantFrame)

  -- What `Seller` calls to sell an item.
  local C_Container = {}
  local ContainerSpy = Mocks:CreateSpy(C_Container)
  ContainerSpy:Stub("UseContainerItem")
  Context:SetGlobal("C_Container", C_Container)

  local JunkFilter = {}
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsSellableJunkItem"):Returns(true)

  local JunkItemsCache = {}
  local JunkItemsCacheSpy = Mocks:CreateSpy(JunkItemsCache)
  JunkItemsCacheSpy:Stub("GetSellableJunkItems"):Returns({})
  JunkItemsCacheSpy:Stub("GetNumSellBlockedJunkItems"):Returns(0)

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemStillInBags"):Returns(true)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)
  ItemsSpy:Stub("IsItemRefundable"):Returns(false)

  local StateManager = {}
  local StateManagerSpy = Mocks:CreateSpy(StateManager)
  StateManagerSpy:Stub("GetGlobalState"):Returns({ safeSell = false })
  StateManagerSpy:Stub("GetProfileState"):Returns({ settings = { autoRepair = false, autoSell = false } })

  Context:SetModule("JunkFilter", JunkFilter)
  Context:SetModule("JunkItemsCache", JunkItemsCache)
  Context:SetModule("Items", Items)
  Context:SetModule("Locale", {
    CANNOT_SELL_WITHOUT_MERCHANT = "CANNOT_SELL_WITHOUT_MERCHANT",
    CANNOT_SELL_ANY_JUNK_ITEMS_NOW = "CANNOT_SELL_ANY_JUNK_ITEMS_NOW",
    NO_JUNK_ITEMS_TO_SELL = "NO_JUNK_ITEMS_TO_SELL"
  })
  Context:SetModule("StateManager", StateManager)

  Context:Load("src/services/seller.lua")

  --- @class SellerTestSpies
  local spies = {
    --- Records the `Addon:Print()` calls.
    AddonSpy = AddonSpy,

    --- Stubs `BagItemsCache:WhenSettled()`, which calls back at once with `true`.
    BagItemsCacheSpy = BagItemsCacheSpy,

    --- Records the `C_Container.UseContainerItem()` calls.
    ContainerSpy = ContainerSpy,

    --- Stubs the `Items` methods that check whether an item can be sold.
    ItemsSpy = ItemsSpy,

    --- Stubs `JunkFilter:IsSellableJunkItem()`, which is true for every item.
    JunkFilterSpy = JunkFilterSpy,

    --- Stubs `JunkItemsCache:GetSellableJunkItems()`, which returns the lowest price first.
    JunkItemsCacheSpy = JunkItemsCacheSpy,

    --- Stubs whether the merchant window is shown.
    MerchantFrameSpy = MerchantFrameSpy,

    --- Stubs the global state, which holds the Safe Sell option.
    StateManagerSpy = StateManagerSpy
  }

  return Context:GetModule("Seller"), Game, spies
end

--- Moves the game's time forward by `count` sales, plus a frame so the last sale has run.
--- @param game TestGameInstance
--- @param count integer
local function advanceSales(game, count)
  game:Advance(count * SALE_SECONDS + game.FRAME_SECONDS)
end

--- Calls the callback of the `waitNumber`th `WhenSettled()` call, as the bag items cache does when it settles.
--- @param whenSettled MockSpyStub The stub of `BagItemsCache:WhenSettled()`.
--- @param waitNumber integer Which call to answer, in the order `Seller` made them.
local function callWaiter(whenSettled, waitNumber)
  local callback = whenSettled.calls[waitNumber][2]
  callback(true)
end

--- Returns `count` items in slots 1 to `count` of `bag`. Each ID is unique to its slot.
--- @param bag integer
--- @param count integer
--- @return BagItem[]
local function createItems(bag, count)
  local items = {}
  for slot = 1, count do
    items[slot] = { bag = bag, slot = slot, id = bag * 1000 + slot }
  end
  return items
end

-- ============================================================================
-- Tests - Seller:Start()
-- ============================================================================

-- Test: sells the last item in the list first, one item per sale.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local middle = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, middle, highest })

  Seller:Start()
  assert(#spies.ContainerSpy.calls == 0)

  advanceSales(Game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 }
  }))

  advanceSales(Game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 2 }
  }))

  advanceSales(Game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 2 },
    { "UseContainerItem", 0, 1 }
  }))
end

-- Test: fires `SellerStarted` when it starts and `SellerStopped` on the sale after the last item.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local started, stopped = 0, 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  assert(started == 1)
  assert(stopped == 0)

  advanceSales(Game, 2)
  assert(started == 1)
  assert(stopped == 0)

  advanceSales(Game, 1)
  assert(started == 1)
  assert(stopped == 1)
end

-- Test: fires `AttemptedToSellItem` for each item, in order.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 2)

  assert(Matchers:IsDeepEqual(attempted, { second, first }))
end

-- Test: fires `AttemptedToSellItem` with the `RUN` attempt type for the items of a run.
do
  local Seller, Game, spies = setupContext()
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ { bag = 0, slot = 1 } })

  local attemptTypes = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(_, attemptType)
    attemptTypes[#attemptTypes + 1] = attemptType
  end)

  Seller:Start()
  advanceSales(Game, 1)

  assert(Matchers:IsDeepEqual(attemptTypes, { "RUN" }))
end

-- Test: with Safe Sell on, asks for items up to the Safe Sell limit.
do
  local Seller, _, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  local getSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")

  Seller:Start()

  assert(#getSellableJunkItems.calls == 1)
  assert(getSellableJunkItems.calls[1][2] == Seller.SAFE_SELL_LIMIT)
end

-- Test: with Safe Sell off, asks for items with no limit.
do
  local Seller, _, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = false })
  local getSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")

  Seller:Start()

  assert(#getSellableJunkItems.calls == 1)
  assert(getSellableJunkItems.calls[1][2] == nil)
end

-- Test: skips an item that is no longer in the bags.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local gone = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, gone, highest })
  spies.ItemsSpy:GetStub("IsItemStillInBags"):Invokes(function(_, item) return item ~= gone end)

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end

-- Test: skips an item that is locked.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local locked = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, locked, highest })
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item == locked end)

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end

-- Test: skips an item that is refundable.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local refundable = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, refundable, highest })
  spies.ItemsSpy:GetStub("IsItemRefundable"):Invokes(function(_, item) return item == refundable end)

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end

-- Test: stops the run when every item is refundable.
do
  local Seller, Game, spies = setupContext()
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ { bag = 0, slot = 1 }, { bag = 0, slot = 2 } })
  spies.ItemsSpy:GetStub("IsItemRefundable"):Returns(true)

  Seller:Start()
  advanceSales(Game, 3)

  assert(#spies.ContainerSpy.calls == 0)
  assert(not Seller:IsBusy())
end

-- Test: skips an item that is no longer sellable junk.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local stale = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, stale, highest })
  spies.JunkFilterSpy:GetStub("IsSellableJunkItem"):Invokes(function(_, item) return item ~= stale end)

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end

-- ============================================================================
-- Tests - Seller:Start() guards
-- ============================================================================

-- Test: prints a message instead of starting when the merchant window is not shown.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  spies.MerchantFrameSpy:GetStub("IsShown"):Returns(false)
  local Print = spies.AddonSpy:GetStub("Print")

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start()
  advanceSales(Game, 1)

  assert(Matchers:IsDeepEqual(Print.calls, { { "CANNOT_SELL_WITHOUT_MERCHANT" } }))
  assert(started == 0)
  assert(not Seller:IsBusy())
  assert(#spies.ContainerSpy.calls == 0)
end

-- Test: prints a message instead of starting when there are no items to sell.
do
  local Seller, Game, spies = setupContext()
  local Print = spies.AddonSpy:GetStub("Print")

  local started, stopped = 0, 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)

  assert(Matchers:IsDeepEqual(Print.calls, { { "NO_JUNK_ITEMS_TO_SELL" } }))
  assert(started == 0)
  assert(stopped == 0)
  assert(not Seller:IsBusy())
end

-- Test: prints a message about blocked junk items instead of the no junk items message.
do
  local Seller, Game, spies = setupContext()
  spies.JunkItemsCacheSpy:GetStub("GetNumSellBlockedJunkItems"):Returns(2)
  local Print = spies.AddonSpy:GetStub("Print")

  Seller:Start()
  advanceSales(Game, 1)

  assert(Matchers:IsDeepEqual(Print.calls, { { "CANNOT_SELL_ANY_JUNK_ITEMS_NOW" } }))
end

-- Test: prints nothing when there are no items to sell and the start is automatic.
do
  local Seller, Game, spies = setupContext()
  local Print = spies.AddonSpy:GetStub("Print")

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start(true)
  advanceSales(Game, 1)

  assert(#Print.calls == 0)
  assert(started == 0)
  assert(not Seller:IsBusy())
end

-- Test: does not start again while a run is in progress.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start()
  Seller:Start()

  assert(#GetSellableJunkItems.calls == 1)
  assert(started == 1)

  advanceSales(Game, 2)
  assert(#spies.ContainerSpy.calls == 2)
end

-- ============================================================================
-- Tests - Seller:Stop() triggers
-- ============================================================================

-- Test: stops the run when the merchant window closes.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  local third = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second, third })

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)
  assert(#spies.ContainerSpy.calls == 1)

  Game:Fire(Game.E.Wow.MerchantClosed)
  assert(stopped == 1)
  assert(not Seller:IsBusy())

  advanceSales(Game, 2)
  assert(#spies.ContainerSpy.calls == 1)
end

-- Test: stops the run when the vendor does not buy the item.
do
  local Seller, Game, spies = setupContext()
  Game.Blizzard.Strings = { VENDOR_DOESNT_BUY_ERROR_TEXT = "VENDOR_DOESNT_BUY_ERROR_TEXT" }
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  local third = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second, third })

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)
  assert(#spies.ContainerSpy.calls == 1)

  Game:Fire(Game.E.Wow.UIErrorMessage, 0, "VENDOR_DOESNT_BUY_ERROR_TEXT")
  assert(stopped == 1)
  assert(not Seller:IsBusy())

  advanceSales(Game, 2)
  assert(#spies.ContainerSpy.calls == 1)
end

-- Test: keeps the run going on any other error message.
do
  local Seller, Game, spies = setupContext()
  Game.Blizzard.Strings = { VENDOR_DOESNT_BUY_ERROR_TEXT = "VENDOR_DOESNT_BUY_ERROR_TEXT" }
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)

  Game:Fire(Game.E.Wow.UIErrorMessage, 0, "ANOTHER_ERROR_TEXT")
  assert(stopped == 0)
  assert(Seller:IsBusy())

  advanceSales(Game, 1)
  assert(#spies.ContainerSpy.calls == 2)
end

-- Test: stops the run when the merchant window is not shown at the next sale.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  local third = { bag = 0, slot = 3 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second, third })

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)
  assert(#spies.ContainerSpy.calls == 1)

  spies.MerchantFrameSpy:GetStub("IsShown"):Returns(false)
  advanceSales(Game, 1)

  assert(#spies.ContainerSpy.calls == 1)
  assert(stopped == 1)
  assert(not Seller:IsBusy())
end

-- ============================================================================
-- Tests - Seller MerchantShow
-- ============================================================================

-- Test: with Auto Sell on, starts selling once the delay after the merchant window opens has passed.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetProfileState"):Returns({ settings = { autoRepair = false, autoSell = true } })
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Game:Fire(Game.E.Wow.MerchantShow)
  Game:Advance(Seller.ON_MERCHANT_SHOW_DELAY - Game.FRAME_SECONDS)
  assert(started == 0)
  assert(not Seller:IsBusy())

  Game:Advance(Game.FRAME_SECONDS)
  assert(started == 1)
  assert(Seller:IsBusy())
  assert(#spies.ContainerSpy.calls == 0)

  advanceSales(Game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, { { "UseContainerItem", second.bag, second.slot } }))
end

-- Test: with Auto Sell on, prints nothing when there are no items to sell.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetProfileState"):Returns({ settings = { autoRepair = false, autoSell = true } })

  Game:Fire(Game.E.Wow.MerchantShow)
  Game:Advance(Seller.ON_MERCHANT_SHOW_DELAY + Game.FRAME_SECONDS)

  assert(#spies.AddonSpy:GetStub("Print").calls == 0)
  assert(not Seller:IsBusy())
end

-- Test: with Auto Sell off, does not start selling.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })

  Game:Fire(Game.E.Wow.MerchantShow)
  Game:Advance(Seller.ON_MERCHANT_SHOW_DELAY + Game.FRAME_SECONDS)
  advanceSales(Game, 1)

  assert(#GetSellableJunkItems.calls == 0)
  assert(not Seller:IsBusy())
  assert(#spies.ContainerSpy.calls == 0)
end

-- ============================================================================
-- Tests - Seller:HandleItem()
-- ============================================================================

-- Test: sells the item at once and fires `AttemptedToSellItem` with it.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 2, slot = 5 }

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(attemptedItem)
    attempted[#attempted + 1] = attemptedItem
  end)

  Seller:HandleItem(item)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, { { "UseContainerItem", 2, 5 } }))
  assert(Matchers:IsDeepEqual(attempted, { item }))
  assert(not Seller:IsBusy())
end

-- Test: fires `AttemptedToSellItem` with the `MANUAL` attempt type for a single item.
do
  local Seller, Game = setupContext()

  local attemptTypes = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(_, attemptType)
    attemptTypes[#attemptTypes + 1] = attemptType
  end)

  Seller:HandleItem({ bag = 2, slot = 5 })

  assert(Matchers:IsDeepEqual(attemptTypes, { "MANUAL" }))
end

-- Test: prints a message instead of selling when the merchant window is not shown.
do
  local Seller, Game, spies = setupContext()
  spies.MerchantFrameSpy:GetStub("IsShown"):Returns(false)
  local item = { bag = 2, slot = 5 }

  local attempted = 0
  Game.EventManager:On(Game.E.AttemptedToSellItem, function() attempted = attempted + 1 end)

  Seller:HandleItem(item)

  assert(Matchers:IsDeepEqual(spies.AddonSpy:GetStub("Print").calls, { { "CANNOT_SELL_WITHOUT_MERCHANT" } }))
  assert(#spies.ContainerSpy.calls == 0)
  assert(attempted == 0)
end

-- Test: does nothing while a run is in progress.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local other = { bag = 2, slot = 5 }
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ first })

  local attempted = 0
  Game.EventManager:On(Game.E.AttemptedToSellItem, function() attempted = attempted + 1 end)

  Seller:Start()
  Seller:HandleItem(other)

  assert(#spies.ContainerSpy.calls == 0)
  assert(attempted == 0)
end

-- ============================================================================
-- Tests - Seller:Start() waiting
-- ============================================================================

-- Test: waits for the bag items cache to settle before getting the items.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start()

  assert(#WhenSettled.calls == 1)
  assert(WhenSettled.calls[1][1] == Seller.MAX_SETTLE_SECONDS)
  assert(Seller:IsBusy())
  assert(#GetSellableJunkItems.calls == 0)
  assert(started == 0)

  callWaiter(WhenSettled, 1)

  assert(#GetSellableJunkItems.calls == 1)
  assert(started == 1)
  assert(Seller:IsBusy())

  advanceSales(Game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, { { "UseContainerItem", item.bag, item.slot } }))
end

-- Test: does not start again while waiting.
do
  local Seller, _, spies = setupContext()
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  Seller:Start()
  Seller:Start()

  assert(#WhenSettled.calls == 1)
  assert(#spies.AddonSpy:GetStub("Print").calls == 0)
end

-- Test: prints a message and ends the run when the wait finds no items to sell.
do
  local Seller, Game, spies = setupContext()
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  local started, stopped = 0, 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  assert(Seller:IsBusy())

  callWaiter(WhenSettled, 1)

  assert(Matchers:IsDeepEqual(spies.AddonSpy:GetStub("Print").calls, { { "NO_JUNK_ITEMS_TO_SELL" } }))
  assert(not Seller:IsBusy())
  assert(started == 0)
  assert(stopped == 0)
end

-- Test: stopping during the wait fires no events and never gets the items.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  local started, stopped = 0, 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  Seller:Stop()
  assert(not Seller:IsBusy())

  callWaiter(WhenSettled, 1)

  assert(#GetSellableJunkItems.calls == 0)
  assert(started == 0)
  assert(stopped == 0)
  assert(not Seller:IsBusy())
end

-- Test: ends the run without a message when the merchant window is not shown after the wait.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start()
  spies.MerchantFrameSpy:GetStub("IsShown"):Returns(false)
  callWaiter(WhenSettled, 1)

  assert(#GetSellableJunkItems.calls == 0)
  assert(#spies.AddonSpy:GetStub("Print").calls == 0)
  assert(started == 0)
  assert(not Seller:IsBusy())
end

-- Test: only the latest wait starts when the run is stopped and started again during the wait.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled"):Returns()

  local started = 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)

  Seller:Start()
  Seller:Stop()
  Seller:Start()
  assert(#WhenSettled.calls == 2)

  callWaiter(WhenSettled, 1)
  assert(#GetSellableJunkItems.calls == 0)
  assert(started == 0)
  assert(Seller:IsBusy())

  callWaiter(WhenSettled, 2)
  assert(#GetSellableJunkItems.calls == 1)
  assert(started == 1)
end

-- ============================================================================
-- Tests - Seller:Start() loop
-- ============================================================================

-- Test: gets the items again after a batch is sold, firing one `SellerStarted` and one `SellerStopped`.
do
  local Seller, Game, spies = setupContext()
  local first = { bag = 0, slot = 1, id = 1 }
  local second = { bag = 0, slot = 2, id = 2 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:ReturnsInOrder({ first }, { second }, {})

  local started, stopped = 0, 0
  Game.EventManager:On(Game.E.SellerStarted, function() started = started + 1 end)
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 5)

  assert(#GetSellableJunkItems.calls == 3)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", first.bag, first.slot },
    { "UseContainerItem", second.bag, second.slot }
  }))
  assert(started == 1)
  assert(stopped == 1)
  assert(not Seller:IsBusy())
end

-- Test: does not attempt a slot again while it holds the same item.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1, id = 1 }
  local sameItem = { bag = 0, slot = 1, id = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:ReturnsInOrder({ item }, { sameItem })

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 5)

  assert(#GetSellableJunkItems.calls == 2)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, { { "UseContainerItem", item.bag, item.slot } }))
  assert(stopped == 1)
end

-- Test: attempts a slot again when it holds a different item.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1, id = 1 }
  local differentItem = { bag = 0, slot = 1, id = 2 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:ReturnsInOrder({ item }, { differentItem }, {})

  Seller:Start()
  advanceSales(Game, 5)

  assert(#spies.ContainerSpy.calls == 2)
end

-- Test: attempts the same item in a different slot.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1, id = 1 }
  local sameItemElsewhere = { bag = 0, slot = 2, id = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:ReturnsInOrder({ item }, { sameItemElsewhere }, {})

  Seller:Start()
  advanceSales(Game, 5)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", item.bag, item.slot },
    { "UseContainerItem", sameItemElsewhere.bag, sameItemElsewhere.slot }
  }))
end

-- Test: ends the run when a batch makes no attempts.
do
  local Seller, Game, spies = setupContext()
  local stale = { bag = 0, slot = 1, id = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ stale })
  spies.JunkFilterSpy:GetStub("IsSellableJunkItem"):Returns(false)
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled")

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 3)

  assert(#WhenSettled.calls == 1)
  assert(#GetSellableJunkItems.calls == 1)
  assert(stopped == 1)
  assert(not Seller:IsBusy())
end

-- Test: stopping between batches fires `SellerStopped` once and ignores the pending wait.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1, id = 1 }
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):Returns({ item })
  local WhenSettled = spies.BagItemsCacheSpy:GetStub("WhenSettled")

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()

  -- The second wait is left pending.
  WhenSettled:Returns()
  advanceSales(Game, 2)
  assert(#WhenSettled.calls == 2)
  assert(Seller:IsBusy())

  Seller:Stop()
  assert(stopped == 1)
  assert(not Seller:IsBusy())

  callWaiter(WhenSettled, 2)
  assert(#GetSellableJunkItems.calls == 1)
  assert(stopped == 1)
end

-- ============================================================================
-- Tests - Seller:Start() Safe Sell
-- ============================================================================

-- Test: with Safe Sell on, ends the run without another fetch when a batch spends the limit.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:ReturnsInOrder(createItems(0, Seller.SAFE_SELL_LIMIT), createItems(1, Seller.SAFE_SELL_LIMIT))

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)

  assert(#spies.ContainerSpy.calls == Seller.SAFE_SELL_LIMIT)
  assert(#GetSellableJunkItems.calls == 1)
  assert(stopped == 1)
end

-- Test: with Safe Sell on, spends the limit across batches, then ends the run.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  -- The first batch leaves room for one more sale.
  local numFirstBatch = Seller.SAFE_SELL_LIMIT - 1
  GetSellableJunkItems:ReturnsInOrder(createItems(0, numFirstBatch), createItems(1, Seller.SAFE_SELL_LIMIT))

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)

  -- Only the first item of the second batch is sold.
  local calls = spies.ContainerSpy.calls
  assert(#calls == Seller.SAFE_SELL_LIMIT)
  assert(Matchers:IsDeepEqual(calls[numFirstBatch + 1], { "UseContainerItem", 1, 1 }))
  assert(#GetSellableJunkItems.calls == 2)
  assert(stopped == 1)
  assert(not Seller:IsBusy())
end

-- Test: with Safe Sell on, an item that was not sold counts nothing against the limit.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  local items = createItems(0, Seller.SAFE_SELL_LIMIT)
  local gone = items[1]
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems"):ReturnsInOrder(items, createItems(1, Seller.SAFE_SELL_LIMIT))
  spies.ItemsSpy:GetStub("IsItemStillInBags"):Invokes(function(_, item) return item ~= gone end)

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)

  -- The first batch attempts one fewer than the limit, so the second batch keeps one item.
  local calls = spies.ContainerSpy.calls
  assert(#calls == Seller.SAFE_SELL_LIMIT)
  assert(Matchers:IsDeepEqual(calls[#calls], { "UseContainerItem", 1, 1 }))
end

-- Test: with Safe Sell turned on during a run, ends the run at the limit.
do
  local Seller, Game, spies = setupContext()
  local GetSellableJunkItems = spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:Returns(createItems(0, Seller.SAFE_SELL_LIMIT * 2))

  local stopped = 0
  Game.EventManager:On(Game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  advanceSales(Game, 1)
  assert(#spies.ContainerSpy.calls == 1)

  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)

  assert(#spies.ContainerSpy.calls == Seller.SAFE_SELL_LIMIT)
  assert(#GetSellableJunkItems.calls == 1)
  assert(stopped == 1)
end

-- Test: with Safe Sell off, sells past the limit across batches.
do
  local Seller, Game, spies = setupContext()
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
      :ReturnsInOrder(createItems(0, Seller.SAFE_SELL_LIMIT), createItems(1, 1), {})

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)

  assert(#spies.ContainerSpy.calls == Seller.SAFE_SELL_LIMIT + 1)
end

-- Test: with Safe Sell on, a new run starts with the whole limit.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })
  -- One list per run, since a run empties the list it sells.
  spies.JunkItemsCacheSpy:GetStub("GetSellableJunkItems")
      :ReturnsInOrder(createItems(0, Seller.SAFE_SELL_LIMIT), createItems(0, Seller.SAFE_SELL_LIMIT))

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)
  assert(#spies.ContainerSpy.calls == Seller.SAFE_SELL_LIMIT)
  assert(not Seller:IsBusy())

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT * 2)
  assert(#spies.ContainerSpy.calls == Seller.SAFE_SELL_LIMIT * 2)
end
