--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `ItemFilters` and `Locale` from a new context, with the mock modules set.
--- @param modules? table<string, table> Mock modules by name.
--- @return ItemFilters ItemFilters
--- @return Locale L
local function setupContext(modules)
  local Context = Harness:NewContext()

  for name, module in pairs(modules or {}) do Context:SetModule(name, module) end
  Context:Load("src/locales/_enUS.lua")
  Context:Load("src/junk-filter/item-filters.lua")

  return Context:GetModule("ItemFilters"), Context:GetModule("Locale")
end

-- ============================================================================
-- Tests - Results
-- ============================================================================

-- Test: the results are three different values.
do
  local ItemFilters = setupContext()
  assert(ItemFilters.JUNK ~= ItemFilters.NOT_JUNK)
  assert(ItemFilters.JUNK ~= ItemFilters.PASS)
  assert(ItemFilters.NOT_JUNK ~= ItemFilters.PASS)
end

-- ============================================================================
-- Tests - ItemFilters:Refundable()
-- ============================================================================

-- Test: a refundable item is not junk, with the refundable reason.
do
  local ItemFilters, L = setupContext({
    Items = { IsItemRefundable = function() return true end }
  })

  local result, reason = ItemFilters:Refundable({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == L.ITEM_IS_REFUNDABLE)
end

-- Test: an item that is not refundable passes, with no reason.
do
  local ItemFilters = setupContext({
    Items = { IsItemRefundable = function() return false end }
  })

  local result, reason = ItemFilters:Refundable({})

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:Locked()
-- ============================================================================

-- Test: a locked item is not junk, with the locked reason.
do
  local ItemFilters, L = setupContext({
    Items = { IsItemLocked = function() return true end }
  })

  local result, reason = ItemFilters:Locked({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == L.ITEM_IS_LOCKED)
end

-- Test: an item that is not locked passes, with no reason.
do
  local ItemFilters = setupContext({
    Items = { IsItemLocked = function() return false end }
  })

  local result, reason = ItemFilters:Locked({})

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end
