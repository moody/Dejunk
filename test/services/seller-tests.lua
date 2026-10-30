--- @diagnostic disable: undefined-global

local FakeGame = require("test/fake-game")
local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- The seconds between sales.
local SALE_SECONDS = 0.2

--- Returns `Seller`, a fake game, and the spies of the modules it uses, from a new context. The merchant is open,
--- Safe Sell is off, and nothing is sellable. A test changes a stub with `GetStub()`.
--- @return Seller Seller
--- @return FakeGameInstance game
--- @return SellerTestSpies spies
local function setupContext()
  local Context = Harness:NewContext()
  Context.Addon.IS_VANILLA = false
  Context.Addon.IS_TBC = false

  local game = FakeGame:Create(Context)

  -- The `Addon` helpers that `Seller` calls.
  Mocks:CreateSpy(Context.Addon):Stub("GetLatency"):Returns(SALE_SECONDS)
  Mocks:CreateSpy(Context:GetModule("Confirmer")):Stub("IsBusy"):Returns(false)

  local MerchantFrame = {}
  Mocks:CreateSpy(MerchantFrame):Stub("IsShown"):Returns(true)
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
  Context:SetModule("Locale", {})
  Context:SetModule("StateManager", StateManager)

  Context:Load("src/services/seller.lua")

  --- @class SellerTestSpies
  local spies = {
    --- Records the `C_Container.UseContainerItem()` calls.
    ContainerSpy = ContainerSpy,

    --- Stubs the `Items` methods that check whether an item can be sold.
    ItemsSpy = ItemsSpy,

    --- Stubs `JunkFilter:GetSellableJunkItems()`, which returns the lowest price first.
    JunkFilterSpy = JunkFilterSpy,

    --- Stubs the global state, which holds the Safe Sell option.
    StateManagerSpy = StateManagerSpy
  }

  return Context:GetModule("Seller"), game, spies
end

--- Moves the game's time forward by `count` sales, plus a frame so the last sale has run.
--- @param game FakeGameInstance
--- @param count integer
local function advanceSales(game, count)
  game.Advance(count * SALE_SECONDS + FakeGame.FRAME_SECONDS)
end

-- ============================================================================
-- Tests - Seller:Start()
-- ============================================================================

-- Test: sells the last item in the list first, one item per sale.
do
  local Seller, game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local middle = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, middle, highest })

  Seller:Start()
  assert(#spies.ContainerSpy.calls == 0)

  advanceSales(game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 }
  }))

  advanceSales(game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 2 }
  }))

  advanceSales(game, 1)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 2 },
    { "UseContainerItem", 0, 1 }
  }))
end

-- Test: fires `SellerStarted` when it starts and `SellerStopped` on the sale after the last item.
do
  local Seller, game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local started, stopped = 0, 0
  game.EventManager:On(game.E.SellerStarted, function() started = started + 1 end)
  game.EventManager:On(game.E.SellerStopped, function() stopped = stopped + 1 end)

  Seller:Start()
  assert(started == 1)
  assert(stopped == 0)

  advanceSales(game, 2)
  assert(started == 1)
  assert(stopped == 0)

  advanceSales(game, 1)
  assert(started == 1)
  assert(stopped == 1)
end

-- Test: fires `AttemptedToSellItem` for each item, in order.
do
  local Seller, game, spies = setupContext()
  local first = { bag = 0, slot = 1 }
  local second = { bag = 0, slot = 2 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ first, second })

  local attempted = {}
  game.EventManager:On(game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(game, 2)

  assert(Matchers:IsDeepEqual(attempted, { second, first }))
end

-- Test: with Safe Sell on, sells only the first items in the list, up to the limit.
do
  local Seller, game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = true })

  local items = {}
  for slot = 1, Seller.SAFE_SELL_LIMIT + 2 do items[slot] = { bag = 0, slot = slot } end
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns(items)

  local expectedCalls = {}
  for slot = Seller.SAFE_SELL_LIMIT, 1, -1 do expectedCalls[#expectedCalls + 1] = { "UseContainerItem", 0, slot } end

  Seller:Start()
  advanceSales(game, Seller.SAFE_SELL_LIMIT)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, expectedCalls))

  -- Nothing more is sold.
  advanceSales(game, 3)
  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, expectedCalls))
end

-- Test: with Safe Sell off, sells every item.
do
  local Seller, game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeSell = false })

  local count = Seller.SAFE_SELL_LIMIT + 2
  local items = {}
  for slot = 1, count do items[slot] = { bag = 0, slot = slot } end
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns(items)

  Seller:Start()
  advanceSales(game, count)

  assert(#spies.ContainerSpy.calls == count)
end

-- Test: skips an item that is no longer in the bags.
do
  local Seller, game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local gone = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, gone, highest })
  spies.ItemsSpy:GetStub("IsItemStillInBags"):Invokes(function(_, item) return item ~= gone end)

  local attempted = {}
  game.EventManager:On(game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end

-- Test: skips an item that is locked.
do
  local Seller, game, spies = setupContext()
  local lowest = { bag = 0, slot = 1 }
  local locked = { bag = 0, slot = 2 }
  local highest = { bag = 0, slot = 3 }
  spies.JunkFilterSpy:GetStub("GetSellableJunkItems"):Returns({ lowest, locked, highest })
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item == locked end)

  local attempted = {}
  game.EventManager:On(game.E.AttemptedToSellItem, function(item) attempted[#attempted + 1] = item end)

  Seller:Start()
  advanceSales(game, 3)

  assert(Matchers:IsDeepEqual(spies.ContainerSpy.calls, {
    { "UseContainerItem", 0, 3 },
    { "UseContainerItem", 0, 1 }
  }))
  assert(Matchers:IsDeepEqual(attempted, { highest, lowest }))
end
