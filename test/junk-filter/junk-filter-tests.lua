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

--- @class TestJunkFilterOptions
--- @field addon? table Fields set on the addon, such as `IS_RETAIL`. The game version flags are `false` otherwise.

--- Returns `JunkFilter` from a new context where its collaborators are mocks, and the spies of the `ItemFilters` and
--- `Items` mocks. Every `ItemFilters` method is stubbed to return `PASS`, and the item is in the bags and can be sold
--- and destroyed. A test stubs a method again to change what it returns.
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
  ItemFiltersSpy:Stub("Refundable"):Returns(PASS)
  ItemFiltersSpy:Stub("Locked"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeAboveItemLevel"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeAbovePrice"):Returns(PASS)
  ItemFiltersSpy:Stub("ByLists"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeEquipmentSets"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeUnboundEquipment"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeWarbandEquipment"):Returns(PASS)
  ItemFiltersSpy:Stub("ExcludeByEquipmentType"):Returns(PASS)
  ItemFiltersSpy:Stub("IncludeByQuality"):Returns(PASS)
  ItemFiltersSpy:Stub("IncludeBelowItemLevel"):Returns(PASS)
  ItemFiltersSpy:Stub("IncludeBelowPrice"):Returns(PASS)
  ItemFiltersSpy:Stub("IncludeByEquipmentType"):Returns(PASS)
  ItemFiltersSpy:Stub("IncludeArtifactRelics"):Returns(PASS)

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
  Context:SetModule("Locale", { NO_FILTERS_MATCHED = "no filters matched" })
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
