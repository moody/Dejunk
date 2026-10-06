--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")

-- ============================================================================
-- Setup
-- ============================================================================

--- The WoW item quality values that the filters compare against.
local Enum = { ItemQuality = { Poor = 0, Common = 1, Uncommon = 2, Rare = 3, Epic = 4 } }

--- Returns `ItemFilters` and `Locale` from a new context, with the mock modules set. The colors return their
--- text unchanged.
--- @param modules? table<string, table> Mock modules by name.
--- @return ItemFilters ItemFilters
--- @return Locale L
local function setupContext(modules)
  local Context = Harness:NewContext()
  Context:SetGlobal("Enum", Enum)

  for name, module in pairs(modules or {}) do Context:SetModule(name, module) end

  local Colors = Context:GetModule("Colors")
  Colors.Grey = function(text) return text end
  Colors.Yellow = function(text) return text end

  Context:Load("src/locales/_enUS.lua")
  Context:Load("src/junk-filter/item-filters.lua")

  return Context:GetModule("ItemFilters"), Context:GetModule("Locale")
end

--- Returns a state with every quality selected.
--- @return ItemQualitiesState qualities
local function getQualities()
  return { poor = true, common = true, uncommon = true, rare = true, epic = true }
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

-- ============================================================================
-- Tests - ItemFilters:ExcludeAboveItemLevel()
-- ============================================================================

-- Test: equipment above the item level is not junk, with a reason naming the option.
do
  local ItemFilters = setupContext({
    Items = {
      IsItemEquipment = function() return true end,
      GetItemLevel = function() return 60 end
    }
  })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Options > Exclude Above Item Level (50)")
end

-- Test: passes when the option is disabled.
do
  local ItemFilters = setupContext({
    Items = {
      IsItemEquipment = function() return true end,
      GetItemLevel = function() return 60 end
    }
  })
  local state = { enabled = false, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local ItemFilters = setupContext({
    Items = {
      IsItemEquipment = function() return false end,
      GetItemLevel = function() return 60 end
    }
  })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item level is not above the value.
do
  local ItemFilters = setupContext({
    Items = {
      IsItemEquipment = function() return true end,
      GetItemLevel = function() return 50 end
    }
  })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local ItemFilters = setupContext({
    Items = {
      IsItemEquipment = function() return true end,
      GetItemLevel = function() return 60 end
    }
  })
  local qualities = { poor = true, common = true, uncommon = true, rare = true, epic = false }
  local state = { enabled = true, value = 50, qualities = qualities }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end
