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

--- Returns a mock list with the given name that contains every item, or none.
--- @param name string
--- @param containsItems boolean
--- @return table
local function mockList(name, containsItems)
  return { name = name, Contains = function() return containsItems end }
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

-- ============================================================================
-- Tests - ItemFilters:ByLists()
-- ============================================================================

-- Test: an item on the profile exclusions list is not junk, with the list as the reason.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", true),
      ProfileInclusions = mockList("Profile Inclusions", false),
      GlobalExclusions = mockList("Global Exclusions", false),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result, reason = ItemFilters:ByLists({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Lists > Profile Exclusions")
end

-- Test: an item on the profile inclusions list is junk, with the list as the reason.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", true),
      GlobalExclusions = mockList("Global Exclusions", false),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result, reason = ItemFilters:ByLists({})

  assert(result == ItemFilters.JUNK)
  assert(reason == "Lists > Profile Inclusions")
end

-- Test: an item on the global exclusions list is not junk, with the list as the reason.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", false),
      GlobalExclusions = mockList("Global Exclusions", true),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result, reason = ItemFilters:ByLists({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Lists > Global Exclusions")
end

-- Test: an item on the global inclusions list is junk, with the list as the reason.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", false),
      GlobalExclusions = mockList("Global Exclusions", false),
      GlobalInclusions = mockList("Global Inclusions", true)
    }
  })

  local result, reason = ItemFilters:ByLists({})

  assert(result == ItemFilters.JUNK)
  assert(reason == "Lists > Global Inclusions")
end

-- Test: an item that is on no list passes, with no reason.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", false),
      GlobalExclusions = mockList("Global Exclusions", false),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result, reason = ItemFilters:ByLists({})

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: a profile exclusion wins over a profile inclusion.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", true),
      ProfileInclusions = mockList("Profile Inclusions", true),
      GlobalExclusions = mockList("Global Exclusions", false),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result = ItemFilters:ByLists({})

  assert(result == ItemFilters.NOT_JUNK)
end

-- Test: a profile inclusion wins over a global exclusion.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", true),
      GlobalExclusions = mockList("Global Exclusions", true),
      GlobalInclusions = mockList("Global Inclusions", false)
    }
  })

  local result = ItemFilters:ByLists({})

  assert(result == ItemFilters.JUNK)
end

-- Test: a global exclusion wins over a global inclusion.
do
  local ItemFilters = setupContext({
    Lists = {
      ProfileExclusions = mockList("Profile Exclusions", false),
      ProfileInclusions = mockList("Profile Inclusions", false),
      GlobalExclusions = mockList("Global Exclusions", true),
      GlobalInclusions = mockList("Global Inclusions", true)
    }
  })

  local result = ItemFilters:ByLists({})

  assert(result == ItemFilters.NOT_JUNK)
end

-- ============================================================================
-- Tests - ItemFilters:ExcludeEquipmentSets()
-- ============================================================================

-- Test: an item in an equipment set is not junk, with a reason naming the option.
do
  local ItemFilters = setupContext()

  local result, reason = ItemFilters:ExcludeEquipmentSets({ isEquipmentSet = true }, true)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Options > Exclude Equipment Sets")
end

-- Test: passes when the option is disabled.
do
  local ItemFilters = setupContext()

  local result, reason = ItemFilters:ExcludeEquipmentSets({ isEquipmentSet = true }, false)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not in an equipment set.
do
  local ItemFilters = setupContext()

  local result, reason = ItemFilters:ExcludeEquipmentSets({ isEquipmentSet = false }, true)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end
