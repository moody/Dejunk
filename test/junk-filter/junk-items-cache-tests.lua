--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `JunkItemsCache` from a new context where its collaborators are mocks, the `JunkFilter` mock, and the
--- spies of the `Items` and `BagItemsCache` mocks. No item is locked.
--- @return JunkItemsCache JunkItemsCache
--- @return table JunkFilter
--- @return MockSpy ItemsSpy
--- @return MockSpy BagItemsCacheSpy
local function setupContext()
  local Context = Harness:NewContext()

  local BagItemsCache = {}
  local BagItemsCacheSpy = Mocks:CreateSpy(BagItemsCache)

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)

  local JunkFilter = {}

  Context:SetModule("BagItemsCache", BagItemsCache)
  Context:SetModule("Items", Items)
  Context:SetModule("JunkFilter", JunkFilter)
  Context:Load("src/junk-filter/junk-items-cache.lua")

  return Context:GetModule("JunkItemsCache"), JunkFilter, ItemsSpy, BagItemsCacheSpy
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

-- ============================================================================
-- Tests - JunkItemsCache:GetNumSellBlockedJunkItems()
-- ============================================================================

-- Test: counts the junk items for selling that cannot be sold right now.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {
    { isJunk = true, isBlocked = true },
    { isJunk = true, isBlocked = true },
    { isJunk = true },
    { isBlocked = true },
    {}
  })
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsJunkItem"):Invokes(function(_, item) return item.isJunk == true end)
  JunkFilterSpy:Stub("GetSellBlockReason"):Invokes(function(_, item) return item.isBlocked and "reason" or nil end)

  assert(JunkItemsCache:GetNumSellBlockedJunkItems() == 2)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetJunkItems()
-- ============================================================================

-- Test: returns the array it is given.
do
  local JunkItemsCache, _, _, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {})
  local given = {}

  assert(JunkItemsCache:GetJunkItems(given) == given)
end

-- Test: keeps the items that IsJunkItem finds junk, with its reason, and removes the rest.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA, itemB, itemC, itemD = { id = 1 }, { id = 2 }, { id = 3 }, { id = 4 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Invokes(function(_, item, filterType)
    assert(filterType == nil, "GetJunkItems must ask IsJunkItem without a filter type")
    return item == itemC, "junk reason"
  end)

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { { id = 3, reason = "junk reason" } }))
end

-- Test: sorts by the price of the whole stack, lowest first.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 4, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemC, itemA, itemB }))
end

-- Test: sorts items of the same price by quality, lowest first.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 3 }
  local itemB = { name = "a", price = 5, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: sorts items of the same price and quality by name.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "b", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 5, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: sorts items of the same price, quality, and name by quantity, lowest first.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 2, quantity = 2, quality = 1 }
  local itemB = { name = "a", price = 4, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  local itemD = { name = "a", price = 1, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems(nil, 2)

  assert(Matchers:IsDeepEqual(result, { itemD, itemB }))
end

-- Test: keeps every item when `limit` is more than the number of junk items.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetJunkItems(nil, 10)

  assert(Matchers:IsDeepEqual(result, { itemB, itemA }))
end

-- Test: keeps locked items, without checking them.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  local result = JunkItemsCache:GetJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemA, itemB }))
  assert(#IsItemLockedStub.calls == 0)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetSellableJunkItems()
-- ============================================================================

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetSellableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out locked items.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1, isLocked = true }
  local itemD = { name = "a", price = 4, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC, itemD })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetSellableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB, itemD }))
end

-- Test: skips locked items without counting them toward `limit`.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  local itemC = { name = "a", price = 3, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetSellableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- ============================================================================
-- Tests - JunkItemsCache:GetDestroyableJunkItems()
-- ============================================================================

-- Test: keeps only the first `limit` items in sort order.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(true, "reason")

  local result = JunkItemsCache:GetDestroyableJunkItems(nil, 1)

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- Test: leaves out locked items.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 1, quantity = 1, quality = 1, isLocked = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1 }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local result = JunkItemsCache:GetDestroyableJunkItems()

  assert(Matchers:IsDeepEqual(result, { itemB }))
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNumJunkItems()
-- ============================================================================

-- Test: returns how many items are sellable junk and how many are destroyable junk.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1, canSell = true },
    { name = "a", price = 1, quantity = 1, quality = 1, canSell = true },
    { name = "a", price = 1, quantity = 1, quality = 1, canSell = true, canDestroy = true },
    { name = "a", price = 1, quantity = 1, quality = 1, canDestroy = true },
    { name = "a", price = 1, quantity = 1, quality = 1 }
  })
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsSellableJunkItem"):Invokes(function(_, item)
    return item.canSell == true, "reason"
  end)
  JunkFilterSpy:Stub("IsDestroyableJunkItem"):Invokes(function(_, item)
    return item.canDestroy == true, "reason"
  end)

  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 3)
  assert(numDestroyable == 2)
end

-- Test: does not count locked items.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1, canSell = true, isLocked = true },
    { name = "a", price = 2, quantity = 1, quality = 1, canSell = true },
    { name = "a", price = 3, quantity = 1, quality = 1, canDestroy = true, isLocked = true },
    { name = "a", price = 4, quantity = 1, quality = 1, canDestroy = true }
  })
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsSellableJunkItem"):Invokes(function(_, item)
    return item.canSell == true, "reason"
  end)
  JunkFilterSpy:Stub("IsDestroyableJunkItem"):Invokes(function(_, item)
    return item.canDestroy == true, "reason"
  end)
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()

  assert(numSellable == 1)
  assert(numDestroyable == 1)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNextSellableJunkItem()
-- ============================================================================

-- Test: returns the first sellable junk item in sort order.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1, canSell = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, canSell = true }
  local itemC = { name = "a", price = 1, quantity = 1, quality = 1, canSell = false }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC })
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsSellableJunkItem"):Invokes(function(_, item)
    return item.canSell, "reason"
  end)

  assert(JunkItemsCache:GetNextSellableJunkItem() == itemB)
end

-- Test: returns nil when no item is sellable junk.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, { {} })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(false)

  assert(JunkItemsCache:GetNextSellableJunkItem() == nil)
end

-- Test: skips a locked item.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, isLocked = true }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  assert(JunkItemsCache:GetNextSellableJunkItem() == itemA)
end

-- Test: returns nil when every sellable junk item is locked.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, { { name = "a", price = 2, quantity = 1, quality = 1 } })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  assert(JunkItemsCache:GetNextSellableJunkItem() == nil)
end

-- Test: stops checking locks at the first item that is not locked.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1 },
    { name = "a", price = 2, quantity = 1, quality = 1 },
    { name = "a", price = 3, quantity = 1, quality = 1 }
  })
  Mocks:CreateSpy(JunkFilter):Stub("IsSellableJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = ItemsSpy:GetStub("IsItemLocked"):Returns(false)

  JunkItemsCache:GetNextSellableJunkItem()

  assert(#IsItemLockedStub.calls == 1)
end

-- ============================================================================
-- Tests - JunkItemsCache:GetNextDestroyableJunkItem()
-- ============================================================================

-- Test: returns the first destroyable junk item in sort order.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1, canDestroy = true }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, canDestroy = true }
  local itemC = { name = "a", price = 1, quantity = 1, quality = 1, canDestroy = false }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB, itemC })
  local JunkFilterSpy = Mocks:CreateSpy(JunkFilter)
  JunkFilterSpy:Stub("IsDestroyableJunkItem"):Invokes(function(_, item)
    return item.canDestroy, "reason"
  end)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == itemB)
end

-- Test: returns nil when no item is destroyable junk.
do
  local JunkItemsCache, JunkFilter, _, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, { {} })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(false)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == nil)
end

-- Test: skips a locked item.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  local itemA = { name = "a", price = 5, quantity = 1, quality = 1 }
  local itemB = { name = "a", price = 2, quantity = 1, quality = 1, isLocked = true }
  stubGetItems(BagItemsCacheSpy, { itemA, itemB })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Invokes(function(_, item) return item.isLocked == true end)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == itemA)
end

-- Test: returns nil when every destroyable junk item is locked.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, { { name = "a", price = 2, quantity = 1, quality = 1 } })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(true, "reason")
  ItemsSpy:GetStub("IsItemLocked"):Returns(true)

  assert(JunkItemsCache:GetNextDestroyableJunkItem() == nil)
end

-- Test: stops checking locks at the first item that is not locked.
do
  local JunkItemsCache, JunkFilter, ItemsSpy, BagItemsCacheSpy = setupContext()
  stubGetItems(BagItemsCacheSpy, {
    { name = "a", price = 1, quantity = 1, quality = 1 },
    { name = "a", price = 2, quantity = 1, quality = 1 },
    { name = "a", price = 3, quantity = 1, quality = 1 }
  })
  Mocks:CreateSpy(JunkFilter):Stub("IsDestroyableJunkItem"):Returns(true, "reason")
  local IsItemLockedStub = ItemsSpy:GetStub("IsItemLocked"):Returns(false)

  JunkItemsCache:GetNextDestroyableJunkItem()

  assert(#IsItemLockedStub.calls == 1)
end

print("All assertions passed.")
