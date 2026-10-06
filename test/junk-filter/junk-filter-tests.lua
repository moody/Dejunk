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
  "Refundable",
  "Locked",
  "ExcludeAboveItemLevel",
  "ExcludeAbovePrice",
  "ByLists",
  "ExcludeEquipmentSets",
  "ExcludeUnboundEquipment",
  "ExcludeWarbandEquipment",
  "ExcludeByEquipmentType",
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

--- Returns `JunkFilter` from a new context where its collaborators are mocks, and the spies of the `ItemFilters` and
--- `Items` mocks. Every `ItemFilters` method is stubbed to return `PASS`, and the item is in the bags and can be sold
--- and destroyed. A test changes what a method returns with `GetStub()`.
--- @param options? TestJunkFilterOptions
--- @return JunkFilter JunkFilter
--- @return MockSpy ItemFiltersSpy
--- @return MockSpy ItemsSpy
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
  ItemsSpy:Stub("IsItemSellable"):Returns(true)
  ItemsSpy:Stub("IsItemDestroyable"):Returns(true)

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
      includeByQuality = "includeByQuality",
      includeBelowItemLevel = "includeBelowItemLevel",
      includeBelowPrice = "includeBelowPrice",
      includeByEquipmentType = "includeByEquipmentType",
      includeArtifactRelics = "includeArtifactRelics"
    }
  })

  Context:SetModule("ItemFilters", ItemFilters)
  Context:SetModule("Items", Items)
  Context:SetModule("Locale", { NO_FILTERS_MATCHED = "NO_FILTERS_MATCHED" })
  Context:SetModule("StateManager", StateManager)
  Context:Load("src/junk-filter/junk-filter.lua")

  return Context:GetModule("JunkFilter"), ItemFiltersSpy, ItemsSpy
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() filters
-- ============================================================================

-- Test: calls the filters in order with the item and the state of each option.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })

  local item = { id = 1 }
  JunkFilter:IsJunkItem(item, "SELL")

  assert(Matchers:IsDeepEqual(ItemFiltersSpy.calls, {
    { "Refundable", item },
    { "Locked", item },
    { "ExcludeAboveItemLevel", item, "excludeAboveItemLevel" },
    { "ExcludeAbovePrice", item, "excludeAbovePrice", "SELL" },
    { "ByLists", item },
    { "ExcludeEquipmentSets", item, "excludeEquipmentSets" },
    { "ExcludeUnboundEquipment", item, "excludeUnboundEquipment" },
    { "ExcludeWarbandEquipment", item, "excludeWarbandEquipment" },
    { "ExcludeByEquipmentType", item, "excludeByEquipmentType" },
    { "IncludeByQuality", item, "includeByQuality" },
    { "IncludeBelowItemLevel", item, "includeBelowItemLevel" },
    { "IncludeBelowPrice", item, "includeBelowPrice", "SELL" },
    { "IncludeByEquipmentType", item, "includeByEquipmentType" },
    { "IncludeArtifactRelics", item, "includeArtifactRelics" }
  }))
end

-- Test: passes the destroy filter type to the price filters.
do
  local JunkFilter, ItemFiltersSpy = setupContext()
  local ExcludeAbovePrice = ItemFiltersSpy:Stub("ExcludeAbovePrice"):Returns(PASS)
  local IncludeBelowPrice = ItemFiltersSpy:Stub("IncludeBelowPrice"):Returns(PASS)
  local item = { id = 1 }

  JunkFilter:IsJunkItem(item, "DESTROY")

  assert(Matchers:IsDeepEqual(ExcludeAbovePrice.calls, { { item, "excludeAbovePrice", "DESTROY" } }))
  assert(Matchers:IsDeepEqual(IncludeBelowPrice.calls, { { item, "includeBelowPrice", "DESTROY" } }))
end

-- Test: skips the equipment sets filter on Classic Era.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_VANILLA = true } })
  local ExcludeEquipmentSets = ItemFiltersSpy:Stub("ExcludeEquipmentSets"):Returns(PASS)

  JunkFilter:IsJunkItem({})

  assert(#ExcludeEquipmentSets.calls == 0)
end

-- Test: skips the equipment sets filter on TBC Classic.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_TBC = true } })
  local ExcludeEquipmentSets = ItemFiltersSpy:Stub("ExcludeEquipmentSets"):Returns(PASS)

  JunkFilter:IsJunkItem({})

  assert(#ExcludeEquipmentSets.calls == 0)
end

-- Test: skips the warband equipment and artifact relics filters when the client is not Retail.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = false } })
  local ExcludeWarbandEquipment = ItemFiltersSpy:Stub("ExcludeWarbandEquipment"):Returns(PASS)
  local IncludeArtifactRelics = ItemFiltersSpy:Stub("IncludeArtifactRelics"):Returns(PASS)

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
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })
  ItemFiltersSpy:GetStub(name):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true, name)
  assert(reason == "junk reason", name)
  for laterIndex = index + 1, #ORDERED_FILTER_NAMES do
    local laterName = ORDERED_FILTER_NAMES[laterIndex]
    assert(#ItemFiltersSpy:GetStub(laterName).calls == 0, name .. " then " .. laterName)
  end
end

-- Test: each filter's NOT_JUNK result is returned as not junk with its reason, without calling the filters after it.
for index, name in ipairs(ORDERED_FILTER_NAMES) do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })
  ItemFiltersSpy:GetStub(name):Returns(NOT_JUNK, "not junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false, name)
  assert(reason == "not junk reason", name)
  for laterIndex = index + 1, #ORDERED_FILTER_NAMES do
    local laterName = ORDERED_FILTER_NAMES[laterIndex]
    assert(#ItemFiltersSpy:GetStub(laterName).calls == 0, name .. " then " .. laterName)
  end
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() item checks
-- ============================================================================

-- Test: returns false without calling any filter when the item is no longer in the bags.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemStillInBags"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "SELL")

  assert(isJunk == false)
  assert(reason == nil)
  assert(#ItemFiltersSpy.calls == 0)
end

-- Test: for selling, returns false without calling any filter when the item cannot be sold.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemSellable"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "SELL")

  assert(isJunk == false)
  assert(reason == nil)
  assert(#ItemFiltersSpy.calls == 0)
end

-- Test: for selling, calls the filters when the item can be sold but not destroyed.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)

  JunkFilter:IsJunkItem({}, "SELL")

  assert(#ItemFiltersSpy.calls > 0)
end

-- Test: for destroying, returns false without calling any filter when the item cannot be destroyed.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({}, "DESTROY")

  assert(isJunk == false)
  assert(reason == nil)
  assert(#ItemFiltersSpy.calls == 0)
end

-- Test: for destroying, calls the filters when the item can be destroyed but not sold.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemSellable"):Returns(false)

  JunkFilter:IsJunkItem({}, "DESTROY")

  assert(#ItemFiltersSpy.calls > 0)
end

-- ============================================================================
-- Tests - JunkFilter:IsJunkItem() filter type
-- ============================================================================

-- Test: with no filter type, calls every filter twice, once for selling and once for destroying.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })

  JunkFilter:IsJunkItem({})

  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#ItemFiltersSpy:GetStub(name).calls == 2, name)
  end
end

-- Test: for selling, calls every filter once.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })

  JunkFilter:IsJunkItem({}, "SELL")

  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: for destroying, calls every filter once.
do
  local JunkFilter, ItemFiltersSpy = setupContext({ addon = { IS_RETAIL = true } })

  JunkFilter:IsJunkItem({}, "DESTROY")

  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: with no filter type, a filter that returns JUNK is called once, so the destroying pass is skipped.
do
  local JunkFilter, ItemFiltersSpy = setupContext()
  local FirstFilter = ItemFiltersSpy:GetStub(FIRST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true)
  assert(reason == "junk reason")
  assert(#FirstFilter.calls == 1)
end

-- Test: with no filter type, a filter that returns NOT_JUNK is called twice, once for each pass.
do
  local JunkFilter, ItemFiltersSpy = setupContext()
  local FirstFilter = ItemFiltersSpy:GetStub(FIRST_FILTER_NAME):Returns(NOT_JUNK, "not junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false)
  assert(reason == "not junk reason")
  assert(#FirstFilter.calls == 2)
end

-- Test: with no filter type, only the destroying pass runs when the item cannot be sold.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext({ addon = { IS_RETAIL = true } })
  ItemsSpy:GetStub("IsItemSellable"):Returns(false)
  ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(JUNK, "junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == true)
  assert(reason == "junk reason")
  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: with no filter type, only the selling pass runs when the item cannot be destroyed.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext({ addon = { IS_RETAIL = true } })
  ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)
  ItemFiltersSpy:GetStub(LAST_FILTER_NAME):Returns(NOT_JUNK, "not junk reason")

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false)
  assert(reason == "not junk reason")
  for _, name in ipairs(ORDERED_FILTER_NAMES) do
    assert(#ItemFiltersSpy:GetStub(name).calls == 1, name)
  end
end

-- Test: with no filter type, returns false without calling any filter when the item can be neither sold nor destroyed.
do
  local JunkFilter, ItemFiltersSpy, ItemsSpy = setupContext()
  ItemsSpy:GetStub("IsItemSellable"):Returns(false)
  ItemsSpy:GetStub("IsItemDestroyable"):Returns(false)

  local isJunk, reason = JunkFilter:IsJunkItem({})

  assert(isJunk == false)
  assert(reason == nil)
  assert(#ItemFiltersSpy.calls == 0)
end
