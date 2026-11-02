--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `JunkItemsCache` and the spies of its mocks, from a new context where the modules it uses are mocks.
--- A test changes what a method returns with `GetStub()`.
--- @return JunkItemsCache JunkItemsCache
--- @return JunkItemsCacheTestSpies spies
local function setupContext()
  local Context = Harness:NewContext()

  local Blizzard = { Utils = {} }
  local BlizzardUtilsSpy = Mocks:CreateSpy(Blizzard.Utils)
  BlizzardUtilsSpy:Stub("GetTime"):Returns(0)

  -- Each color wraps its text in `name[...]`.
  local Colors = {}
  for _, name in ipairs({ "Grey", "Red", "White" }) do
    Colors[name] = function(text) return name:lower() .. "[" .. text .. "]" end
  end

  local BagItemsCache = {}
  local BagItemsCacheSpy = Mocks:CreateSpy(BagItemsCache)
  BagItemsCacheSpy:Stub("GetVersion"):Returns(0)

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)
  ItemsSpy:Stub("IsItemStillInBags"):Returns(true)

  local JunkFilter = {}
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("GetSellBlockReason"):Returns(nil)

  local StateManager = {}
  local StateManagerSpy = Mocks:CreateSpy(StateManager)
  StateManagerSpy:Stub("GetGlobalState"):Returns({ inclusions = {}, exclusions = {} })
  StateManagerSpy:Stub("GetProfileState"):Returns({ settings = {} })

  Context:SetModule("Blizzard", Blizzard)
  Context:SetModule("BagItemsCache", BagItemsCache)
  Context:SetModule("Colors", Colors)
  Context:SetModule("Items", Items)
  Context:SetModule("JunkFilter", JunkFilter)
  Context:SetModule("StateManager", StateManager)
  Context:Load("src/junk-filter/junk-items-cache.lua")

  --- @class JunkItemsCacheTestSpies
  local spies = {
    --- The version never changes. A test stubs `GetItems()` with `stubGetItems()`.
    BagItemsCacheSpy = BagItemsCacheSpy,

    --- The time is always 0.
    BlizzardUtilsSpy = BlizzardUtilsSpy,

    --- Every item is in the bags and is not locked.
    ItemsSpy = ItemsSpy,

    --- No item is blocked from being sold. A test stubs `IsJunkItem()`.
    JunkFilterSpy = JunkFilterSpy,

    --- The settings and the global lists never change.
    StateManagerSpy = StateManagerSpy
  }

  return Context:GetModule("JunkItemsCache"), spies
end

--- Stubs `BagItemsCache:GetItems()` like the real method: it empties the given array, or a new one, and fills it
--- with `bagItems`.
--- @param bagItemsCacheSpy MockSpy
--- @param bagItems BagItem[]
local function stubGetItems(bagItemsCacheSpy, bagItems)
  bagItemsCacheSpy:Stub("GetItems"):Invokes(function(_, items)
    items = items or {}
    for key in pairs(items) do items[key] = nil end
    for i, item in ipairs(bagItems) do items[i] = item end
    return items
  end)
end

--- Stubs `JunkFilter:IsJunkItem()` so that an item is junk for selling if it is in `sellItems`, and junk for
--- destroying if it is in `destroyItems`.
--- @param junkFilterSpy MockSpy
--- @param sellItems BagItem[]
--- @param destroyItems BagItem[]
local function stubIsJunkItem(junkFilterSpy, sellItems, destroyItems)
  junkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item, filterType)
    for _, junkItem in ipairs(filterType == "SELL" and sellItems or destroyItems) do
      if junkItem == item then return true end
    end
    return false
  end)
end

--- Stubs `JunkFilter:IsJunkItem()` to return `isJunk` and `"<filterType> reason"`, such as `"SELL reason"`.
--- @param junkFilterSpy MockSpy
--- @param isJunk boolean
local function stubIsJunkItemReason(junkFilterSpy, isJunk)
  junkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, _, filterType) return isJunk, filterType .. " reason" end)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetVersion()
-- ============================================================================

-- Test: stays the same while nothing changes.
do
  local JunkItemsCache = setupContext()
  local version = JunkItemsCache:GetVersion()
  assert(JunkItemsCache:GetVersion() == version)
end

-- Test: increases when the bag items cache changes.
do
  local JunkItemsCache, spies = setupContext()
  local version = JunkItemsCache:GetVersion()

  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)

  assert(JunkItemsCache:GetVersion() > version)
end

-- Test: increases when the active profile's settings change.
do
  local JunkItemsCache, spies = setupContext()
  local version = JunkItemsCache:GetVersion()

  spies.StateManagerSpy:GetStub("GetProfileState"):Returns({ settings = {} })

  assert(JunkItemsCache:GetVersion() > version)
end

-- Test: increases when a global list changes.
do
  for _, listKey in ipairs({ "inclusions", "exclusions" }) do
    local JunkItemsCache, spies = setupContext()
    local globalState = { inclusions = {}, exclusions = {} }
    spies.StateManagerSpy:GetStub("GetGlobalState"):Returns(globalState)
    local version = JunkItemsCache:GetVersion()

    spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({
      inclusions = globalState.inclusions,
      exclusions = globalState.exclusions,
      [listKey] = {}
    })

    assert(JunkItemsCache:GetVersion() > version, listKey)
  end
end

-- Test: stays the same when other global state changes.
do
  local JunkItemsCache, spies = setupContext()
  local globalState = { inclusions = {}, exclusions = {}, points = {} }
  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns(globalState)
  local version = JunkItemsCache:GetVersion()

  spies.StateManagerSpy:GetStub("GetGlobalState"):Returns({
    inclusions = globalState.inclusions,
    exclusions = globalState.exclusions,
    points = {}
  })

  assert(JunkItemsCache:GetVersion() == version)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetJunkItems()
-- ============================================================================

-- Test: returns the array it is given.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, {})
  local given = {}

  assert(JunkItemsCache:GetJunkItems(given) == given)
end

-- Test: keeps the items that are junk, and removes the rest.
do
  local JunkItemsCache, spies = setupContext()
  local itemA, itemB, itemC, itemD = { id = 1 }, { id = 2 }, { id = 3 }, { id = 4 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item) return item == itemC end)

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemC }))
end

-- Test: keeps the items that are junk only for selling, and removes the rest.
do
  local JunkItemsCache, spies = setupContext()
  local sellOnly = { name = "a", price = 1, quantity = 1, quality = 1 }
  local both = { name = "a", price = 2, quantity = 1, quality = 1 }
  local notJunk = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { sellOnly, both, notJunk })
  stubIsJunkItem(spies.JunkFilterSpy, { sellOnly, both }, { both })

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { sellOnly, both }))
end

-- Test: keeps the items that are junk only for destroying, and removes the rest.
do
  local JunkItemsCache, spies = setupContext()
  local destroyOnly = { name = "a", price = 1, quantity = 1, quality = 1 }
  local both = { name = "a", price = 2, quantity = 1, quality = 1 }
  local notJunk = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { destroyOnly, both, notJunk })
  stubIsJunkItem(spies.JunkFilterSpy, { both }, { destroyOnly, both })

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { destroyOnly, both }))
end

-- Test: sorts by the price of the whole stack, lowest first.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 4, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemC, itemA, itemB }))
end

-- Test: sorts items of the same price by quality, lowest first.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 3 }
  local itemB = { name = "a", price = 5, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: sorts items of the same price and quality by name.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "b", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 5, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: sorts items of the same price, quality, and name by quantity, lowest first.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 2, quantity = 2, quality = 1 }
  local itemB = { name = "a", price = 4, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  local itemD = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems(nil, 2)

  assert(Matchers:IsDeepEqual(result, { itemD, itemB }))
end

-- Test: keeps every item when `limit` is more than the number of junk items.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems(nil, 10)

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: keeps locked items, without checking them.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemA, itemB }))
  assert(#IsItemLockedStub.calls == 0)
end

-- Test: leaves out an item that is no longer in the bags.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  JunkItemsCache:GetJunkItems()

  spies.ItemsSpy:GetStub("IsItemStillInBags"):Invokes(function(_, item) return item ~= itemA end)
  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- ============================================================================
-- Tests - JunkItemsCache junk items and the version
-- ============================================================================

-- Test: runs the filters once for each item, selling and destroying, however many times the items are read.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  local IsJunkItemStub = spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  JunkItemsCache:GetJunkItems()
  JunkItemsCache:GetSellableJunkItems()
  JunkItemsCache:GetDestroyableJunkItems()
  JunkItemsCache:IsSellableJunkItem(item)
  JunkItemsCache:IsDestroyableJunkItem(item)

  assert(#IsJunkItemStub.calls == 2)
  assert(IsJunkItemStub.calls[1][2] == "SELL")
  assert(IsJunkItemStub.calls[2][2] == "DESTROY")
end

-- Test: runs the filters again when the version changes.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 1, quantity = 1, quality = 1 } })
  local IsJunkItemStub = spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  JunkItemsCache:GetJunkItems()

  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)
  JunkItemsCache:GetJunkItems()

  assert(#IsJunkItemStub.calls == 4)
end

-- Test: finds the junk items in the bag items of the new version.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local bagItems = { itemA }
  stubGetItems(spies.BagItemsCacheSpy, bagItems)
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  JunkItemsCache:GetJunkItems()

  bagItems[1] = itemB
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)
  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- ============================================================================
-- Tests - JunkItemsCache:GetSellableJunkItems()
-- ============================================================================

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetSellableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out the items that are junk only for destroying.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  stubIsJunkItem(spies.JunkFilterSpy, { itemB }, { itemA, itemB })

  local result = JunkItemsCache:GetSellableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out locked items.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1, isLocked = true }
  local itemD = { name = "a", price = 4, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetSellableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemD }))
end

-- Test: skips locked items without counting them toward `limit`.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetSellableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out items that cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isBlocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Invokes(function(_, item)
    return item.isBlocked and "reason" or nil
  end)

  local result = JunkItemsCache:GetSellableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out an item that is no longer in the bags.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  JunkItemsCache:GetSellableJunkItems()

  spies.ItemsSpy:GetStub("IsItemStillInBags"):Invokes(function(_, item) return item ~= itemA end)
  local result = JunkItemsCache:GetSellableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- ============================================================================
-- Tests - JunkItemsCache:GetDestroyableJunkItems()
-- ============================================================================

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetDestroyableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out the items that are junk only for selling.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  stubIsJunkItem(spies.JunkFilterSpy, { itemA, itemB }, { itemB })

  local result = JunkItemsCache:GetDestroyableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out locked items.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetDestroyableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: keeps items that cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Returns("reason")

  local result = JunkItemsCache:GetDestroyableJunkItems()

  assert(Matchers:IsDeepEqual(result, { item }))
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNumJunkItems()
-- ============================================================================

-- Test: returns how many items are sellable junk and how many are destroyable junk.
do
  local JunkItemsCache, spies = setupContext()
  local sellOnlyA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local sellOnlyB = { name = "a", price = 1, quantity = 1, quality = 1 }
  local both = { name = "a", price = 1, quantity = 1, quality = 1 }
  local destroyOnly = { name = "a", price = 1, quantity = 1, quality = 1 }
  local notJunk = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { sellOnlyA, sellOnlyB, both, destroyOnly, notJunk })
  stubIsJunkItem(spies.JunkFilterSpy, { sellOnlyA, sellOnlyB, both }, { both, destroyOnly })

  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 3)
  assert(numDestroyable == 2)
end

-- Test: does not count locked items.
do
  local JunkItemsCache, spies = setupContext()
  local lockedSell = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local sell = { name = "a", price = 2, quantity = 1, quality = 1 }
  local lockedDestroy = { name = "a", price = 3, quantity = 1, quality = 1, isLocked = true }
  local destroy = { name = "a", price = 4, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { lockedSell, sell, lockedDestroy, destroy })
  stubIsJunkItem(spies.JunkFilterSpy, { lockedSell, sell }, { lockedDestroy, destroy })
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)
end

-- Test: keeps the counts before the interval has passed.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 1, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)

  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)
  spies.BlizzardUtilsSpy:GetStub("GetTime"):Returns(JunkItemsCache.COUNT_INTERVAL_SECONDS - 0.01)
  numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)
end

-- Test: counts again once the interval has passed.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 1, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)

  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)
  spies.BlizzardUtilsSpy:GetStub("GetTime"):Returns(JunkItemsCache.COUNT_INTERVAL_SECONDS)
  numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 0)
  assert(numDestroyable == 0)
end

-- Test: counts again when the version changes.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 1, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)

  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)
  numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 0)
  assert(numDestroyable == 0)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNumJunkItemsText()
-- ============================================================================

-- Test: returns `(-/-)` before the bag items have been scanned.
do
  local JunkItemsCache = setupContext()
  assert(JunkItemsCache:GetNumJunkItemsText() == "grey[(white[-]/red[-])]")
end

-- Test: returns the sellable and destroyable counts once the bag items have been scanned.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  stubIsJunkItem(spies.JunkFilterSpy, { itemA, itemB }, { itemB })
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)

  assert(JunkItemsCache:GetNumJunkItemsText() == "grey[(white[2]/red[1])]")
end

-- Test: returns the new counts when they change.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 1, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)

  assert(JunkItemsCache:GetNumJunkItemsText() == "grey[(white[1]/red[1])]")

  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(2)

  assert(JunkItemsCache:GetNumJunkItemsText() == "grey[(white[0]/red[0])]")
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNumSellBlockedJunkItems()
-- ============================================================================

-- Test: counts the junk items for selling that cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1, isJunk = true, isBlocked = true },
    { name = "a", price = 1, quantity = 1, quality = 1, isJunk = true, isBlocked = true },
    { name = "a", price = 1, quantity = 1, quality = 1, isJunk = true },
    { name = "a", price = 1, quantity = 1, quality = 1, isBlocked = true },
    { name = "a", price = 1, quantity = 1, quality = 1 }
  })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item) return item.isJunk == true end)
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Invokes(function(_, item)
    return item.isBlocked and "reason" or nil
  end)

  assert(JunkItemsCache:GetNumSellBlockedJunkItems() == 2)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNextSellableJunkItem()
-- ============================================================================

-- Test: returns the first sellable junk item in sort order.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1, canSell = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, canSell = true }
  local itemC = { name = "a", price = 1, quantity = 1, quality = 1, canSell = false }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item) return item.canSell end)

  assert(JunkItemsCache:GetNextSellableJunkItem() == itemB)
end

-- Test: returns nil when no item is sellable junk.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { {} })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(false)

  assert(JunkItemsCache:GetNextSellableJunkItem() == nil)
end

-- Test: skips a locked item.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, isLocked = true }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  assert(JunkItemsCache:GetNextSellableJunkItem() == itemA)
end

-- Test: returns nil when every sellable junk item is locked.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 2, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  assert(JunkItemsCache:GetNextSellableJunkItem() == nil)
end

-- Test: stops checking locks at the first item that is not locked.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1 },
    { name = "a", price = 2, quantity = 1, quality = 1 },
    { name = "a", price = 3, quantity = 1, quality = 1 }
  })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = spies.ItemsSpy:GetStub("IsItemLocked"):Returns(false)

  JunkItemsCache:GetNextSellableJunkItem()

  assert(#IsItemLockedStub.calls == 1)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNextDestroyableJunkItem()
-- ============================================================================

-- Test: returns the first destroyable junk item in sort order.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1, canDestroy = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, canDestroy = true }
  local itemC = { name = "a", price = 1, quantity = 1, quality = 1, canDestroy = false }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB, itemC })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item) return item.canDestroy end)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == itemB)
end

-- Test: returns nil when no item is destroyable junk.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { {} })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(false)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == nil)
end

-- Test: skips a locked item.
do
  local JunkItemsCache, spies = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, isLocked = true }
  stubGetItems(spies.BagItemsCacheSpy, { itemA, itemB })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == itemA)
end

-- Test: returns nil when every destroyable junk item is locked.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, { { name = "a", price = 2, quantity = 1, quality = 1 } })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  spies.ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == nil)
end

-- Test: stops checking locks at the first item that is not locked.
do
  local JunkItemsCache, spies = setupContext()
  stubGetItems(spies.BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1 },
    { name = "a", price = 2, quantity = 1, quality = 1 },
    { name = "a", price = 3, quantity = 1, quality = 1 }
  })
  spies.JunkFilterSpy:Stub("IsJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = spies.ItemsSpy:GetStub("IsItemLocked"):Returns(false)

  JunkItemsCache:GetNextDestroyableJunkItem()

  assert(#IsItemLockedStub.calls == 1)
end

-- ============================================================================
-- Tests - JunkItemsCache:IsSellableJunkItem()
-- ============================================================================

-- Test: returns true and the sell reason for a junk item.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, true)

  local isSellableJunk, reason = JunkItemsCache:IsSellableJunkItem(item)

  assert(isSellableJunk == true)
  assert(reason == "SELL reason")
end

-- Test: returns false and the block reason for a junk item that cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, true)
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Returns("block reason")

  local isSellableJunk, reason = JunkItemsCache:IsSellableJunkItem(item)

  assert(isSellableJunk == false)
  assert(reason == "block reason")
end

-- Test: returns false and the sell reason for an item that is not junk, even if it cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, false)
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Returns("block reason")

  local isSellableJunk, reason = JunkItemsCache:IsSellableJunkItem(item)

  assert(isSellableJunk == false)
  assert(reason == "SELL reason")
end

-- Test: returns the reasons of the new items after the version changes.
do
  local JunkItemsCache, spies = setupContext()
  local oldItem = { name = "a", price = 1, quantity = 1, quality = 1 }
  local newItem = { name = "a", price = 2, quantity = 1, quality = 1 }
  local bagItems = { oldItem }
  local reason = "old reason"
  stubGetItems(spies.BagItemsCacheSpy, bagItems)
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function() return true, reason end)
  JunkItemsCache:IsSellableJunkItem(oldItem)

  bagItems[1] = newItem
  reason = "new reason"
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)
  local isNewSellable, newReason = JunkItemsCache:IsSellableJunkItem(newItem)
  local isOldSellable, oldReason = JunkItemsCache:IsSellableJunkItem(oldItem)

  assert(isNewSellable == true)
  assert(newReason == "new reason")
  assert(isOldSellable == false)
  assert(oldReason == nil)
end

-- ============================================================================
-- Tests - JunkItemsCache:IsDestroyableJunkItem()
-- ============================================================================

-- Test: returns true and the destroy reason for a junk item.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, true)

  local isDestroyableJunk, reason = JunkItemsCache:IsDestroyableJunkItem(item)

  assert(isDestroyableJunk == true)
  assert(reason == "DESTROY reason")
end

-- Test: returns false and the destroy reason for an item that is not junk.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, false)

  local isDestroyableJunk, reason = JunkItemsCache:IsDestroyableJunkItem(item)

  assert(isDestroyableJunk == false)
  assert(reason == "DESTROY reason")
end

-- Test: returns true for a junk item that cannot be sold right now.
do
  local JunkItemsCache, spies = setupContext()
  local item = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(spies.BagItemsCacheSpy, { item })
  stubIsJunkItemReason(spies.JunkFilterSpy, true)
  spies.JunkFilterSpy:GetStub("GetSellBlockReason"):Returns("block reason")

  local isDestroyableJunk, reason = JunkItemsCache:IsDestroyableJunkItem(item)

  assert(isDestroyableJunk == true)
  assert(reason == "DESTROY reason")
end

-- Test: returns the reasons of the new items after the version changes.
do
  local JunkItemsCache, spies = setupContext()
  local oldItem = { name = "a", price = 1, quantity = 1, quality = 1 }
  local newItem = { name = "a", price = 2, quantity = 1, quality = 1 }
  local bagItems = { oldItem }
  local reason = "old reason"
  stubGetItems(spies.BagItemsCacheSpy, bagItems)
  spies.JunkFilterSpy:Stub("IsJunkItem"):Invokes(function() return true, reason end)
  JunkItemsCache:IsDestroyableJunkItem(oldItem)

  bagItems[1] = newItem
  reason = "new reason"
  spies.BagItemsCacheSpy:GetStub("GetVersion"):Returns(1)
  local isNewDestroyable, newReason = JunkItemsCache:IsDestroyableJunkItem(newItem)
  local isOldDestroyable, oldReason = JunkItemsCache:IsDestroyableJunkItem(oldItem)

  assert(isNewDestroyable == true)
  assert(newReason == "new reason")
  assert(isOldDestroyable == false)
  assert(oldReason == nil)
end

print("All assertions passed.")
