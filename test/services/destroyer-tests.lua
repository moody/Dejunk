--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Mocks = require("test/mocks")
local TestGame = require("test/test-game")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `Destroyer`, a test game, and the spies of the modules it uses, from a new context. Nothing is busy, the
--- item is in the bags and not locked, Safe Destroy is off, and there is no next junk item. A test changes a stub with
--- `GetStub()`.
--- @return Destroyer Destroyer
--- @return TestGameInstance Game
--- @return DestroyerTestSpies spies
local function setupContext()
  local Context = Harness:NewContext()
  local Game = TestGame:New(Context)

  local AddonSpy = Mocks:CreateSpy(Context.Addon)
  AddonSpy:Stub("IsBusy"):Returns(false)

  -- What `Destroyer` calls to destroy an item.
  local C_Container = {}
  local ContainerSpy = Mocks:CreateSpy(C_Container)
  ContainerSpy:Stub("PickupContainerItem")
  Context:SetGlobal("C_Container", C_Container)
  Context:SetGlobal("ClearCursor", function() end)
  Context:SetGlobal("DeleteCursorItem", function() end)
  Context:SetGlobal("GetCoinTextureString", function(copper) return copper .. "c" end)

  -- Each color returns its text unchanged.
  local Colors = {}
  for _, name in ipairs({ "Grey", "White" }) do
    Colors[name] = function(text) return text end
  end

  local JunkFilter = {}
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "REASON")

  local JunkItemsCache = {}
  local JunkItemsCacheSpy = Mocks:CreateSpy(JunkItemsCache)
  JunkItemsCacheSpy:Stub("GetNextDestroyableJunkItem")

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemStillInBags"):Returns(true)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)

  local Popup = {}
  local PopupSpy = Mocks:CreateSpy(Popup)
  PopupSpy:Stub("Confirm")

  local StateManager = {}
  local StateManagerSpy = Mocks:CreateSpy(StateManager)
  StateManagerSpy:Stub("GetGlobalState"):Returns({ safeDestroy = false })

  Context:SetModule("Colors", Colors)
  Context:SetModule("JunkFilter", JunkFilter)
  Context:SetModule("JunkItemsCache", JunkItemsCache)
  Context:SetModule("Items", Items)
  Context:SetModule("Locale", { DESTROY_ITEM_POPUP_HELP = "DESTROY_ITEM_POPUP_HELP %s" })
  Context:SetModule("Popup", Popup)
  Context:SetModule("StateManager", StateManager)

  Context:Load("src/services/destroyer.lua")

  --- @class DestroyerTestSpies
  local spies = {
    --- Stubs `Addon:IsBusy()`, which is false.
    AddonSpy = AddonSpy,

    --- Records the `C_Container.PickupContainerItem()` calls.
    ContainerSpy = ContainerSpy,

    --- Stubs `JunkFilter:IsJunkItem()`, which is true with a reason for every item.
    JunkFilterSpy = JunkFilterSpy,

    --- Stubs `JunkItemsCache:GetNextDestroyableJunkItem()`, which returns no item.
    JunkItemsCacheSpy = JunkItemsCacheSpy,

    --- Stubs the `Items` methods that check whether an item can be destroyed.
    ItemsSpy = ItemsSpy,

    --- Records the `Popup:Confirm()` calls.
    PopupSpy = PopupSpy,

    --- Stubs the global state, which holds the Safe Destroy option.
    StateManagerSpy = StateManagerSpy
  }

  return Context:GetModule("Destroyer"), Game, spies
end

--- Returns an item that is a stack of one.
--- @return BagItem
local function createItem()
  return { bag = 2, slot = 5, link = "link", quantity = 1, price = 10 }
end

--- Returns a list that receives the attempt of every `AttemptedToDestroyItem` event fired in the game.
--- @param Game TestGameInstance
--- @return DestroyAttempt[] attempts
local function recordAttempts(Game)
  local attempts = {}
  Game.EventManager:On(Game.E.AttemptedToDestroyItem, function(attempt) attempts[#attempts + 1] = attempt end)
  return attempts
end

-- ============================================================================
-- Tests - Destroyer:HandleItem()
-- ============================================================================

-- Test: fires `AttemptedToDestroyItem` with a `MANUAL` attempt of the item and the reason the junk filter gave.
do
  local Destroyer, Game, spies = setupContext()
  local item = createItem()
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(item)

  assert(#attempts == 1)
  assert(attempts[1].item == item)
  assert(attempts[1].type == "MANUAL")
  assert(attempts[1].reason == "REASON")

  local isJunkItemCall = spies.JunkFilterSpy:GetStub("IsJunkItem").calls[1]
  assert(isJunkItemCall[1] == item)
  assert(isJunkItemCall[2] == "DESTROY")
end

-- Test: fires `AttemptedToDestroyItem` with no reason when the junk filter does not call the item junk.
do
  local Destroyer, Game, spies = setupContext()
  spies.JunkFilterSpy:GetStub("IsJunkItem"):Returns(false, "REASON")
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(createItem())

  assert(#attempts == 1)
  assert(attempts[1].reason == nil)
end

-- Test: with Safe Destroy on, fires `AttemptedToDestroyItem` only once the popup is accepted.
do
  local Destroyer, Game, spies = setupContext()
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({ safeDestroy = true })
  local item = createItem()
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(item)

  local confirm = spies.PopupSpy:GetStub("Confirm")
  assert(#confirm.calls == 1)
  assert(#attempts == 0)
  assert(#spies.ContainerSpy.calls == 0)

  confirm.calls[1][1].onAccept()

  assert(#attempts == 1)
  assert(attempts[1].item == item)
  assert(attempts[1].type == "MANUAL")
end

-- Test: does not destroy an item that is locked.
do
  local Destroyer, Game, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(createItem())

  assert(#attempts == 0)
  assert(#spies.ContainerSpy.calls == 0)
end

-- Test: does not destroy an item that is gone from the bags.
do
  local Destroyer, Game, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemStillInBags"):Returns(false)
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(createItem())

  assert(#attempts == 0)
  assert(#spies.ContainerSpy.calls == 0)
end

-- Test: does nothing while busy.
do
  local Destroyer, Game, spies = setupContext()
  spies.AddonSpy:GetStub("IsBusy"):Returns(true)
  local attempts = recordAttempts(Game)

  Destroyer:HandleItem(createItem())

  assert(#attempts == 0)
  assert(#spies.ContainerSpy.calls == 0)
end

-- ============================================================================
-- Tests - Destroyer:Start()
-- ============================================================================

-- Test: fires `AttemptedToDestroyItem` with a `NEXT` attempt of the next junk item and the reason the junk filter gave.
do
  local Destroyer, Game, spies = setupContext()
  local item = createItem()
  spies.JunkItemsCacheSpy:GetStub("GetNextDestroyableJunkItem"):Returns(item)
  local attempts = recordAttempts(Game)

  Destroyer:Start()

  assert(#attempts == 1)
  assert(attempts[1].item == item)
  assert(attempts[1].type == "NEXT")
  assert(attempts[1].reason == "REASON")
end
