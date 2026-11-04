--- @diagnostic disable: undefined-global

local Harness = require("test/harness")
local Matchers = require("test/matchers")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- @type ItemFilterResult
local JUNK = "JUNK"
--- @type ItemFilterResult
local NOT_JUNK = "NOT_JUNK"
--- @type ItemFilterResult
local PASS = "PASS"

--- The `ItemFilters` methods that `JunkFilter:IsJunkItem()` calls, in the order it calls them.
local ORDERED_FILTER_NAMES = {
  "ExcludeAboveItemLevel",
  "ExcludeAbovePrice",
  "ByLists",
  "ExcludeEquipmentSets",
  "ExcludeUnboundEquipment",
  "ExcludeWarbandEquipment",
  "ExcludeByEquipmentType",
  "ExcludeQuestItems",
  "IncludeByQuality",
  "IncludeBelowItemLevel",
  "IncludeBelowPrice",
  "IncludeByEquipmentType",
  "IncludeArtifactRelics"
}

--- The first `ItemFilters` method that `JunkFilter:IsJunkItem()` calls.
local FIRST_FILTER_NAME = ORDERED_FILTER_NAMES[1]

--- The last `ItemFilters` method that `JunkFilter:IsJunkItem()` calls.
local LAST_FILTER_NAME = ORDERED_FILTER_NAMES[#ORDERED_FILTER_NAMES]

--- @class TestJunkFilterOptions
--- @field addon? table Fields set on the addon, such as `IS_RETAIL`. The game version flags are `false` otherwise.

--- Returns `JunkFilter` and the spies of its mocks, from a new context where the modules it uses are mocks.
--- A test changes what a method returns with `GetStub()`.
--- @param options? TestJunkFilterOptions
--- @return JunkFilter JunkFilter
--- @return JunkFilterTestSpies spies
local function setupContext(options)
  options = options or {}

  local Context = Harness:NewContext()
  Context.Addon.IS_RETAIL = false
  Context.Addon.IS_VANILLA = false
  Context.Addon.IS_TBC = false
  Context.Addon.IS_WRATH = false
  Context.Addon.IS_CATA = false
  Context.Addon.IS_MISTS = false
  Context.Addon.IS_FOREVER = false
  for key, value in pairs(options.addon or {}) do Context.Addon[key] = value end

  local ItemFilters = { JUNK = JUNK, NOT_JUNK = NOT_JUNK, PASS = PASS }
  local ItemFiltersSpy = Mocks:CreateSpy(ItemFilters)
  for _, name in ipairs(ORDERED_FILTER_NAMES) do ItemFiltersSpy:Stub(name):Returns(PASS) end

  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemStillInBags"):Returns(true)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)
  ItemsSpy:Stub("IsItemSellable"):Returns(true)
  ItemsSpy:Stub("IsItemDestroyable"):Returns(true)
  ItemsSpy:Stub("IsItemRefundable"):Returns(false)

  local StateManager = {}
  Mocks:CreateSpy(StateManager):Stub("GetProfileState"):Returns({
    -- Each option's state is its own name, so a test can tell which one a filter received.
    settings = {
      excludeAboveItemLevel = "excludeAboveItemLevel",
      excludeAbovePrice = "excludeAbovePrice",
      excludeEquipmentSets = "excludeEquipmentSets",
      excludeUnboundEquipment = "excludeUnboundEquipment",
      excludeWarbandEquipment = "excludeWarbandEquipment",
      excludeByEquipmentType = "excludeByEquipmentType",
      excludeQuestItems = "excludeQuestItems",
      includeByQuality = "includeByQuality",
      includeBelowItemLevel = "includeBelowItemLevel",
      includeBelowPrice = "includeBelowPrice",
      includeByEquipmentType = "includeByEquipmentType",
      includeArtifactRelics = "includeArtifactRelics"
    }
  })

  Context:SetModule("ItemFilters", ItemFilters)
  Context:SetModule("Items", Items)
  Context:SetModule("Locale", {
    ITEM_CANNOT_BE_DESTROYED = "ITEM_CANNOT_BE_DESTROYED",
    ITEM_CANNOT_BE_SOLD = "ITEM_CANNOT_BE_SOLD",
    ITEM_IS_REFUNDABLE = "ITEM_IS_REFUNDABLE",
    NO_FILTERS_MATCHED = "NO_FILTERS_MATCHED"
  })
  Context:SetModule("StateManager", StateManager)
  Context:Load("src/junk-filter/junk-filter.lua")

  --- @class JunkFilterTestSpies
  local spies = {
    --- Every filter returns `PASS`.
    ItemFiltersSpy = ItemFiltersSpy,

    --- Every item is in the bags, is unlocked, is sellable and destroyable, and is not refundable.
    ItemsSpy = ItemsSpy
  }

  return Context:GetModule("JunkFilter"), spies
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() filters
-- ============================================================================

-- Test: calls the filters in order with the item and the state of each option.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })

  local item = { id = 1 }
  JunkFilter:IsJunkItem(item, "SELL")

  assert(Matchers:IsDeepEqual(spies.ItemFiltersSpy.calls, {
    { "ExcludeAboveItemLevel", item, "excludeAboveItemLevel", "SELL" },
    { "ExcludeAbovePrice", item, "excludeAbovePrice", "SELL" },
    { "ByLists", item },
    { "ExcludeEquipmentSets", item, "excludeEquipmentSets", "SELL" },
    { "ExcludeUnboundEquipment", item, "excludeUnboundEquipment", "SELL" },
    { "ExcludeWarbandEquipment", item, "excludeWarbandEquipment", "SELL" },
    { "ExcludeByEquipmentType", item, "excludeByEquipmentType", "SELL" },
    { "ExcludeQuestItems", item, "excludeQuestItems", "SELL" },
    { "IncludeByQuality", item, "includeByQuality", "SELL" },
    { "IncludeBelowItemLevel", item, "includeBelowItemLevel", "SELL" },
    { "IncludeBelowPrice", item, "includeBelowPrice", "SELL" },
    { "IncludeByEquipmentType", item, "includeByEquipmentType", "SELL" },
    { "IncludeArtifactRelics", item, "includeArtifactRelics", "SELL" }
  }))
end

-- Test: passes the destroy filter type to the scoped filters.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  local ExcludeAboveItemLevel = spies.ItemFiltersSpy:GetStub("ExcludeAboveItemLevel")
  local ExcludeAbovePrice = spies.ItemFiltersSpy:GetStub("ExcludeAbovePrice")
  local ExcludeByEquipmentType = spies.ItemFiltersSpy:GetStub("ExcludeByEquipmentType")
  local ExcludeEquipmentSets = spies.ItemFiltersSpy:GetStub("ExcludeEquipmentSets")
  local ExcludeQuestItems = spies.ItemFiltersSpy:GetStub("ExcludeQuestItems")
  local ExcludeUnboundEquipment = spies.ItemFiltersSpy:GetStub("ExcludeUnboundEquipment")
  local ExcludeWarbandEquipment = spies.ItemFiltersSpy:GetStub("ExcludeWarbandEquipment")
  local IncludeArtifactRelics = spies.ItemFiltersSpy:GetStub("IncludeArtifactRelics")
  local IncludeByEquipmentType = spies.ItemFiltersSpy:GetStub("IncludeByEquipmentType")
  local IncludeByQuality = spies.ItemFiltersSpy:GetStub("IncludeByQuality")
  local IncludeBelowItemLevel = spies.ItemFiltersSpy:GetStub("IncludeBelowItemLevel")
  local IncludeBelowPrice = spies.ItemFiltersSpy:GetStub("IncludeBelowPrice")
  local item = { id = 1 }

  JunkFilter:IsJunkItem(item, "DESTROY")

  assert(Matchers:IsDeepEqual(ExcludeAboveItemLevel.calls, { { item, "excludeAboveItemLevel", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeAbovePrice.calls, { { item, "excludeAbovePrice", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeByEquipmentType.calls, { { item, "excludeByEquipmentType", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeEquipmentSets.calls, { { item, "excludeEquipmentSets", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeQuestItems.calls, { { item, "excludeQuestItems", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeUnboundEquipment.calls, { { item, "excludeUnboundEquipment", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(ExcludeWarbandEquipment.calls, { { item, "excludeWarbandEquipment", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeArtifactRelics.calls, { { item, "includeArtifactRelics", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeByEquipmentType.calls, { { item, "includeByEquipmentType", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeByQuality.calls, { { item, "includeByQuality", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeBelowItemLevel.calls, { { item, "includeBelowItemLevel", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeBelowPrice.calls, { { item, "includeBelowPrice", "DESTROY" } }))
end

-- Test: skips the equipment sets filter on Classic Era.
do
  local JunkFilter, spies = setupContext({ addon = { IS_VANILLA = true } })
  local ExcludeEquipmentSets = spies.ItemFiltersSpy:GetStub("ExcludeEquipmentSets")

  JunkFilter:IsJunkItem({})

  assert(#ExcludeEquipmentSets.calls == 0)
end

-- Test: skips the equipment sets filter on TBC Classic.
do
  local JunkFilter, spies = setupContext({ addon = { IS_TBC = true } })
  local ExcludeEquipmentSets = spies.ItemFiltersSpy:GetStub("ExcludeEquipmentSets")

  JunkFilter:IsJunkItem({})

  assert(#ExcludeEquipmentSets.calls == 0)
end

-- Test: skips the warband equipment and artifact relics filters when the client is not Retail.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = false } })
  local ExcludeWarbandEquipment = spies.ItemFiltersSpy:GetStub("ExcludeWarbandEquipment")
  local IncludeArtifactRelics = spies.ItemFiltersSpy:GetStub("IncludeArtifactRelics")

  JunkFilter:IsJunkItem({})

  assert(#ExcludeWarbandEquipment.calls == 0)
  assert(#IncludeArtifactRelics.calls == 0)
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() results
-- ============================================================================

-- Test: returns false and the no filters matched reason when every filter passes.
do
  local JunkFilter = setupContext()

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false)
  assert(reason == "NO_FILTERS_MATCHED")
end

-- Test: each filter's JUNK result is returned as junk with its reason, without calling the filters after it.
for index, name in ipairs(ORDERED_FILTER_NAMES) do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemFiltersSpy:GetStub(name):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true, name)
  assert(reason == "junk reason", name)
  for laterIndex = index + 1, #ORDERED_FILTER_NAMES do
    local laterName = ORDERED_FILTER_NAMES[laterIndex]
    assert(#spies.ItemFiltersSpy:GetStub(laterName).calls == 0, name .. " then " .. laterName)
  end
end

-- Test: each filter's NOT_JUNK result is returned as not junk with its reason, without calling the filters after it.
for index, name in ipairs(ORDERED_FILTER_NAMES) do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemFiltersSpy:GetStub(name):Returns(NOT_JUNK, "not junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false, name)
  assert(reason == "not junk reason", name)
  for laterIndex = index + 1, #ORDERED_FILTER_NAMES do
    local laterName = ORDERED_FILTER_NAMES[laterIndex]
    assert(#spies.ItemFiltersSpy:GetStub(laterName).calls == 0, name .. " then " .. laterName)
  end
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() item checks
-- ============================================================================

-- Test: returns false without calling any filter when the item is no longer in the bags.
do
  local JunkFilter, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemStillInBags"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "SELL")

  assert(isJunk == false)
  assert(reason == nil)
  assert(#spies.ItemFiltersSpy.calls == 0)
end

-- Test: for selling, returns false with the cannot be sold reason, without calling any filter, when the item cannot be
-- sold.
do
  local JunkFilter, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemSellable"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "SELL")

  assert(isJunk == false)
  assert(reason == "ITEM_CANNOT_BE_SOLD")
  assert(#spies.ItemFiltersSpy.calls == 0)
end

-- Test: for destroying, returns false with the cannot be destroyed reason, without calling any filter, when the item
-- cannot be destroyed.
do
  local JunkFilter, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "DESTROY")

  assert(isJunk == false)
  assert(reason == "ITEM_CANNOT_BE_DESTROYED")
  assert(#spies.ItemFiltersSpy.calls == 0)
end

-- Test: for destroying, returns junk with the filter's reason for an item that cannot be sold.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemsSpy:GetStub("IsItemSellable"):Returns(false)
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({}, "DESTROY")

  assert(isJunk == true)
  assert(reason == "junk reason")
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() filter type
-- ============================================================================

-- Test: with no filter type, calls every filter twice, once for selling and once for destroying.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })

  JunkFilter:IsJunkItem({})

  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#spies.ItemFiltersSpy:GetStub(name).calls == 2, name)
  end
end

-- Test: for destroying, calls every filter once.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })

  JunkFilter:IsJunkItem({}, "DESTROY")

  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#spies.ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: with no filter type, a filter that returns JUNK is called once, so the destroying pass is skipped.
do
  local JunkFilter, spies = setupContext()
  local FirstFilter = spies.ItemFiltersSpy:GetStub(FIRST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true)
  assert(reason == "junk reason")
  assert(#FirstFilter.calls == 1)
end

-- Test: with no filter type, only the destroying pass runs when the item cannot be sold.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemsSpy:GetStub("IsItemSellable"):Returns(false)
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true)
  assert(reason == "junk reason")
  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#spies.ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: with no filter type, only the selling pass runs when the item cannot be destroyed.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(NOT_JUNK, "not junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false)
  assert(reason == "not junk reason")
  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#spies.ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- ============================================================================
-- Tests - JunkFilter:IsSellableJunkItem()
-- ============================================================================

-- Test: IsSellableJunkItem returns junk for an item that can be sold.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsSellableJunkItem({})

  assert(isJunk == true)
  assert(reason == "junk reason")
end

-- Test: IsSellableJunkItem returns false for an item that cannot be sold, even if it can be destroyed.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemsSpy:GetStub("IsItemSellable"):Returns(false)
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsSellableJunkItem({})

  assert(isJunk == false)
  assert(reason == "ITEM_CANNOT_BE_SOLD")
end

-- Test: IsSellableJunkItem returns false with the block reason for a blocked junk item.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  spies.ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")
  spies.ItemsSpy:GetStub("IsItemRefundable"):Returns(true)

  local isJunk, reason = JunkFilter:IsSellableJunkItem({})

  assert(isJunk == false)
  assert(reason == "ITEM_IS_REFUNDABLE")
end

-- Test: IsSellableJunkItem does not look for a block unless the item is junk.
do
  local JunkFilter, spies = setupContext({ addon = { IS_RETAIL = true } })
  JunkFilter:IsSellableJunkItem({})
  assert(#spies.ItemsSpy:GetStub("IsItemRefundable").calls == 0)
end

-- ============================================================================
-- Tests - JunkFilter:GetSellBlockReason()
-- ============================================================================

-- Test: returns the refundable reason for a refundable item.
do
  local JunkFilter, spies = setupContext()
  spies.ItemsSpy:GetStub("IsItemRefundable"):Returns(true)
  assert(JunkFilter:GetSellBlockReason({}) == "ITEM_IS_REFUNDABLE")
end

-- Test: returns nothing when nothing blocks the sale.
do
  local JunkFilter = setupContext()
  assert(JunkFilter:GetSellBlockReason({}) == nil)
end
