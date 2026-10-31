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
--- Safe Sell and Auto Sell are off, and nothing is sellable. A test changes a stub with `GetStub()`.
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

  local MerchantFrame = {}
  local MerchantFrameSpy = Mocks:CreateSpy(MerchantFrame)
  MerchantFrameSpy:Stub("IsShown"):Returns(true)
  Context:SetGlobal("MerchantFrame", MerchantFrame)

  -- What `Seller` calls to sell an item and to close a popup.
  local C_Container = {}
  local ContainerSpy = Mocks:CreateSpy(C_Container)
  ContainerSpy:Stub("UseContainerItem")
  Context:SetGlobal("C_Container", C_Container)
  Context:SetGlobal("StaticPopup_ForEachShownDialog", function() end)

  local JunkFilter = {}
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("GetSellableJunkItems"):Returns({})

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemStillInBags"):Returns(true)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)

  local StateManager = {}
  local StateManagerSpy = Mocks:CreateSpy(StateManager)
  StateManagerSpy:Stub("GetGlobalState"):Returns({ safeSell = false })
  StateManagerSpy:Stub("GetProfileState"):Returns({ settings = { autoRepair = false, autoSell = false } })

  Context:SetModule("JunkFilter", JunkFilter)
  Context:SetModule("Items", Items)
  Context:SetModule("Locale", {
    CANNOT_SELL_WITHOUT_MERCHANT = "CANNOT_SELL_WITHOUT_MERCHANT",
    NO_JUNK_ITEMS_TO_SELL = "NO_JUNK_ITEMS_TO_SELL"
  })
  Context:SetModule("StateManager", StateManager)

  Context:Load("src/services/seller.lua")

  --- @class SellerTestSpies
  local spies = {
    --- Records the `Addon:Print()` calls.
    AddonSpy = AddonSpy,

    --- Records the `C_Container.UseContainerItem()` calls.
    ContainerSpy = ContainerSpy,

    --- Stubs the `Items` methods that check whether an item can be sold.
    ItemsSpy = ItemsSpy,

    --- Stubs `JunkFilter:GetSellableJunkItems()`, which returns the lowest price first.
    JunkFilterSpy = JunkFilterSpy,

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

-- ============================================================================
-- Tests - Seller:Start()
-- ============================================================================

-- Test: sells the last item in the list first, one item per sale.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local middle = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, middle, highest })

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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local attempted = {}
  Game.EventManager:On(Game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(Game, 2)

  assert(Matchers:IsDeepEqual(attempted, { second, first }))
end

-- Test: with Safe Sell on, sells only the first items in the list, up to the limit.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })

  local items = {}
  for slot = 1, Seller.SAFE_SELL_LIMIT + 2 do items[slot] = { bag = 0, slot = slot } end
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns(items)

  local expectedCalls = {}
  for slot = Seller.SAFE_SELL_LIMIT, 1, -1 do expectedCalls[#expectedCalls + 1] = { "UseContainerItem", 0, slot } end

  Seller:Start()
  advanceSales(Game, Seller.SAFE_SELL_LIMIT)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, expectedCalls))

  -- Nothing more is sold.
  advanceSales(Game, 3)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, expectedCalls))
end

-- Test: with Safe Sell off, sells every item.
do
  local Seller, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = false })

  local count = Seller.SAFE_SELL_LIMIT + 2
  local items = {}
  for slot = 1, count do items[slot] = { bag = 0, slot = slot } end
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns(items)

  Seller:Start()
  advanceSales(Game, count)

  assert(#spies.ContainerSpy.calls == count)
end

-- Test: skips an item that is no longer in the bags.
do
  local Seller, Game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local gone = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, gone, highest })
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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, locked, highest })
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

-- ============================================================================
-- Tests - Seller:Start() guards
-- ============================================================================

-- Test: prints a message instead of starting when the merchant window is not shown.
do
  local Seller, Game, spies = setupContext()
  local item = { bag = 0, slot = 1 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ item })
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
  local GetSellableJunkItems = spies.JunkFilterSpy:GetStub("GetSellableJunkItems")
  GetSellableJunkItems:Returns({ first, second })

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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second, third })

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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second, third })

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
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

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
