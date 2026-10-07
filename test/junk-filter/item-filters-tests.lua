--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Mocks = require("test/mocks")

-- ============================================================================
-- Setup
-- ============================================================================

--- The WoW item quality values that the filters compare against.
local Enum = { ItemQuality = { Poor = 0, Common = 1, Uncommon = 2, Rare = 3, Epic = 4 } }

--- Returns `ItemFilters` and `Locale` from a new context, with the mock modules set. The colors return their
--- text unchanged, and coin text is the copper amount followed by `c`.
--- @param modules? table<string, table> Mock modules by name.
--- @return ItemFilters ItemFilters
--- @return Locale L
local function setupContext(modules)
  local Context = Harness:NewContext()
  Context:SetGlobal("Enum", Enum)
  Context:SetGlobal("GetCoinTextureString", function(copper) return copper .. "c" end)

  for name, module in pairs(modules or {}) do Context:SetModule(name, module) end

  local Colors = Context:GetModule("Colors")
  Colors.Grey = function(text) return text end
  Colors.White = function(text) return text end
  Colors.Yellow = function(text) return text end
  Colors.ByQuality = {}

  Context:Load("src/locales/_enUS.lua")
  Context:Load("src/junk-filter/item-filters.lua")

  return Context:GetModule("ItemFilters"), Context:GetModule("Locale")
end

--- Returns a mock list with the given name that contains every item, or none.
--- @param name string
--- @param containsItems boolean
--- @return table
local function mockList(name, containsItems)
  local list = { name = name }
  Mocks:CreateSpy(list):Stub("Contains"):Returns(containsItems)
  return list
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
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemRefundable"):Returns(true)

  local ItemFilters, L = setupContext({ Items = Items })

  local result, reason = ItemFilters:Refundable({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == L.ITEM_IS_REFUNDABLE)
end

-- Test: an item that is not refundable passes, with no reason.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemRefundable"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })

  local result, reason = ItemFilters:Refundable({})

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:Locked()
-- ============================================================================

-- Test: a locked item is not junk, with the locked reason.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemLocked"):Returns(true)

  local ItemFilters, L = setupContext({ Items = Items })

  local result, reason = ItemFilters:Locked({})

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == L.ITEM_IS_LOCKED)
end

-- Test: an item that is not locked passes, with no reason.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemLocked"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })

  local result, reason = ItemFilters:Locked({})

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:ExcludeAboveItemLevel()
-- ============================================================================

-- Test: equipment above the item level is not junk, with a reason naming the option.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(60)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Profile Options > Exclude Above Item Level (50)")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(60)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = false, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(false)
  ItemsSpy:Stub("GetItemLevel"):Returns(60)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item level is not above the value.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(50)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAboveItemLevel({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(60)

  local ItemFilters = setupContext({ Items = Items })
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
  assert(reason == "Profile Options > Exclude Equipment Sets")
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

-- ============================================================================
-- Tests - ItemFilters:ExcludeUnboundEquipment()
-- ============================================================================

-- Test: unbound equipment of a selected quality is not junk, with a reason naming the option.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("IsItemBound"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeUnboundEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Profile Options > Exclude Unbound Equipment")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("IsItemBound"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = false, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeUnboundEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(false)
  ItemsSpy:Stub("IsItemBound"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeUnboundEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is bound.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("IsItemBound"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeUnboundEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("IsItemBound"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })
  local qualities = getQualities()
  qualities.epic = false
  local state = { enabled = true, qualities = qualities }

  local result, reason = ItemFilters:ExcludeUnboundEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:ExcludeWarbandEquipment()
-- ============================================================================

-- Test: warband equipment of a selected quality is not junk, with a reason naming the option.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemWarbandEquipment"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeWarbandEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Profile Options > Exclude Warband Equipment")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemWarbandEquipment"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = false, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeWarbandEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not warband equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemWarbandEquipment"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeWarbandEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemWarbandEquipment"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })
  local qualities = getQualities()
  qualities.epic = false
  local state = { enabled = true, qualities = qualities }

  local result, reason = ItemFilters:ExcludeWarbandEquipment({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:ExcludeByEquipmentType()
-- ============================================================================

-- Test: equipment of a selected type and quality is not junk, with a reason naming the option and the type.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:ExcludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Profile Options > Exclude By Equipment Type (Plate)")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = false, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:ExcludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(false)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:ExcludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's type is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(false)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:ExcludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local qualities = getQualities()
  qualities.epic = false
  local state = { enabled = true, qualities = qualities, armor = {}, weapons = {} }

  local result, reason = ItemFilters:ExcludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:IncludeByQuality()
-- ============================================================================

-- Test: an item of a selected quality is junk, with a reason naming the option.
do
  local ItemFilters = setupContext()
  local state = { enabled = true, scope = "BOTH", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "SELL")

  assert(result == ItemFilters.JUNK)
  assert(reason == "Profile Options > Include By Quality")
end

-- Test: each selected quality includes only items of that quality.
do
  local ItemFilters = setupContext()
  local itemQualities = {
    poor = Enum.ItemQuality.Poor,
    common = Enum.ItemQuality.Common,
    uncommon = Enum.ItemQuality.Uncommon,
    rare = Enum.ItemQuality.Rare,
    epic = Enum.ItemQuality.Epic
  }

  for selectedKey in pairs(itemQualities) do
    local qualities = {}
    for key in pairs(itemQualities) do qualities[key] = key == selectedKey end
    local state = { enabled = true, scope = "BOTH", qualities = qualities }
    for itemKey, itemQuality in pairs(itemQualities) do
      local result = ItemFilters:IncludeByQuality({ quality = itemQuality }, state, "SELL")
      local expected = itemKey == selectedKey and ItemFilters.JUNK or ItemFilters.PASS
      assert(result == expected, selectedKey .. " selected, " .. itemKey .. " item")
    end
  end
end

-- Test: passes when the option is disabled.
do
  local ItemFilters = setupContext()
  local state = { enabled = false, scope = "BOTH", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local ItemFilters = setupContext()
  local qualities = getQualities()
  qualities.poor = false
  local state = { enabled = true, scope = "BOTH", qualities = qualities }

  local result, reason = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: applies when the filter type is the option's scope.
do
  local ItemFilters = setupContext()
  local state = { enabled = true, scope = "SELL", qualities = getQualities() }

  local result = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "SELL")

  assert(result == ItemFilters.JUNK)
end

-- Test: passes when the filter type is not in the option's scope.
do
  local ItemFilters = setupContext()
  local state = { enabled = true, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "DESTROY")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: a scope of both applies to each filter type.
do
  local ItemFilters = setupContext()
  local state = { enabled = true, scope = "BOTH", qualities = getQualities() }

  local sell = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "SELL")
  local destroy = ItemFilters:IncludeByQuality({ quality = Enum.ItemQuality.Poor }, state, "DESTROY")

  assert(sell == ItemFilters.JUNK)
  assert(destroy == ItemFilters.JUNK)
end

-- ============================================================================
-- Tests - ItemFilters:IncludeBelowItemLevel()
-- ============================================================================

-- Test: equipment below the item level is junk, with a reason naming the option and the value.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(40)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowItemLevel({ quality = Enum.ItemQuality.Poor }, state)

  assert(result == ItemFilters.JUNK)
  assert(reason == "Profile Options > Include Below Item Level (50)")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(40)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = false, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowItemLevel({ quality = Enum.ItemQuality.Poor }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(false)
  ItemsSpy:Stub("GetItemLevel"):Returns(40)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowItemLevel({ quality = Enum.ItemQuality.Poor }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item level is not below the value.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(50)

  local ItemFilters = setupContext({ Items = Items })
  local state = { enabled = true, value = 50, qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowItemLevel({ quality = Enum.ItemQuality.Poor }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemLevel"):Returns(40)

  local ItemFilters = setupContext({ Items = Items })
  local qualities = getQualities()
  qualities.poor = false
  local state = { enabled = true, value = 50, qualities = qualities }

  local result, reason = ItemFilters:IncludeBelowItemLevel({ quality = Enum.ItemQuality.Poor }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:IncludeByEquipmentType()
-- ============================================================================

-- Test: equipment of a selected type and quality is junk, with a reason naming the option and the type.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:IncludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.JUNK)
  assert(reason == "Profile Options > Include By Equipment Type (Plate)")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = false, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:IncludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not equipment.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(false)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:IncludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's type is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(false)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local state = { enabled = true, qualities = getQualities(), armor = {}, weapons = {} }

  local result, reason = ItemFilters:IncludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item's quality is not selected.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemEquipment"):Returns(true)
  ItemsSpy:Stub("GetItemSubclassName"):Returns("Plate")
  local EquipmentTypes = {}
  local EquipmentTypesSpy = Mocks:CreateSpy(EquipmentTypes)
  EquipmentTypesSpy:Stub("IsItemTypeSelected"):Returns(true)

  local ItemFilters = setupContext({ Items = Items, EquipmentTypes = EquipmentTypes })
  local qualities = getQualities()
  qualities.epic = false
  local state = { enabled = true, qualities = qualities, armor = {}, weapons = {} }

  local result, reason = ItemFilters:IncludeByEquipmentType({ quality = Enum.ItemQuality.Epic }, state)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:IncludeArtifactRelics()
-- ============================================================================

-- Test: an artifact relic is junk, with a reason naming the option.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemArtifactRelic"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })

  local result, reason = ItemFilters:IncludeArtifactRelics({}, true)

  assert(result == ItemFilters.JUNK)
  assert(reason == "Profile Options > Include Artifact Relics")
end

-- Test: passes when the option is disabled.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemArtifactRelic"):Returns(true)

  local ItemFilters = setupContext({ Items = Items })

  local result, reason = ItemFilters:IncludeArtifactRelics({}, false)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the item is not an artifact relic.
do
  local Items = {}
  local ItemsSpy = Mocks:CreateSpy(Items)
  ItemsSpy:Stub("IsItemArtifactRelic"):Returns(false)

  local ItemFilters = setupContext({ Items = Items })

  local result, reason = ItemFilters:IncludeArtifactRelics({}, true)

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:ExcludeAbovePrice()
-- ============================================================================

-- Test: an item priced above the value is not junk, with a reason naming the option and the value.
do
  local ItemFilters = setupContext()
  local item = { price = 600, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 500, scope = "DESTROY", qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(result == ItemFilters.NOT_JUNK)
  assert(reason == "Profile Options > Exclude Above Price (500c)")
end

-- Test: passes when the option is disabled.
do
  local ItemFilters = setupContext()
  local item = { price = 600, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = false, value = 500, scope = "DESTROY", qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the filter type is not in the option's scope.
do
  local ItemFilters = setupContext()
  local item = { price = 600, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 500, scope = "DESTROY", qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAbovePrice(item, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: a scope of both applies to each filter type, and excludes.
do
  local ItemFilters = setupContext()
  local item = { price = 600, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 500, scope = "BOTH", qualities = getQualities() }

  local sell = ItemFilters:ExcludeAbovePrice(item, state, "SELL")
  local destroy = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(sell == ItemFilters.NOT_JUNK)
  assert(destroy == ItemFilters.NOT_JUNK)
end

-- Test: passes when the price is not above the value.
do
  local ItemFilters = setupContext()
  local item = { price = 500, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 500, scope = "DESTROY", qualities = getQualities() }

  local result, reason = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: compares the price of the whole stack.
do
  local ItemFilters = setupContext()
  local item = { price = 100, quantity = 10, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 500, scope = "DESTROY", qualities = getQualities() }

  local result = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(result == ItemFilters.NOT_JUNK)
end

-- Test: passes for an item with no value.
do
  local ItemFilters = setupContext()
  local flagged = { noValue = true, price = 100, quantity = 1, quality = Enum.ItemQuality.Epic }
  local priceless = { noValue = false, price = 0, quantity = 1, quality = Enum.ItemQuality.Epic }
  local state = { enabled = true, value = 0, scope = "DESTROY", qualities = getQualities() }

  assert(ItemFilters:ExcludeAbovePrice(flagged, state, "DESTROY") == ItemFilters.PASS)
  assert(ItemFilters:ExcludeAbovePrice(priceless, state, "DESTROY") == ItemFilters.PASS)
end

-- Test: passes when the item's quality is not selected.
do
  local ItemFilters = setupContext()
  local item = { price = 600, quantity = 1, quality = Enum.ItemQuality.Epic }
  local qualities = getQualities()
  qualities.epic = false
  local state = { enabled = true, value = 500, scope = "DESTROY", qualities = qualities }

  local result, reason = ItemFilters:ExcludeAbovePrice(item, state, "DESTROY")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- ============================================================================
-- Tests - ItemFilters:IncludeBelowPrice()
-- ============================================================================

-- Test: an item priced below the value is junk, with a reason naming the option and the value.
do
  local ItemFilters = setupContext()
  local item = { price = 400, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "SELL")

  assert(result == ItemFilters.JUNK)
  assert(reason == "Profile Options > Include Below Price (500c)")
end

-- Test: passes when the option is disabled.
do
  local ItemFilters = setupContext()
  local item = { price = 400, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = false, value = 500, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes when the filter type is not in the option's scope.
do
  local ItemFilters = setupContext()
  local item = { price = 400, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "DESTROY")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: a scope of both applies to each filter type, and includes.
do
  local ItemFilters = setupContext()
  local item = { price = 400, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "BOTH", qualities = getQualities() }

  local sell = ItemFilters:IncludeBelowPrice(item, state, "SELL")
  local destroy = ItemFilters:IncludeBelowPrice(item, state, "DESTROY")

  assert(sell == ItemFilters.JUNK)
  assert(destroy == ItemFilters.JUNK)
end

-- Test: passes when the price is not below the value.
do
  local ItemFilters = setupContext()
  local item = { price = 500, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: compares the price of the whole stack.
do
  local ItemFilters = setupContext()
  local item = { price = 100, quantity = 10, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "SELL", qualities = getQualities() }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end

-- Test: passes for an item with no value.
do
  local ItemFilters = setupContext()
  local flagged = { noValue = true, price = 100, quantity = 1, quality = Enum.ItemQuality.Poor }
  local priceless = { noValue = false, price = 0, quantity = 1, quality = Enum.ItemQuality.Poor }
  local state = { enabled = true, value = 500, scope = "SELL", qualities = getQualities() }

  assert(ItemFilters:IncludeBelowPrice(flagged, state, "SELL") == ItemFilters.PASS)
  assert(ItemFilters:IncludeBelowPrice(priceless, state, "SELL") == ItemFilters.PASS)
end

-- Test: passes when the item's quality is not selected.
do
  local ItemFilters = setupContext()
  local item = { price = 400, quantity = 1, quality = Enum.ItemQuality.Poor }
  local qualities = getQualities()
  qualities.poor = false
  local state = { enabled = true, value = 500, scope = "SELL", qualities = qualities }

  local result, reason = ItemFilters:IncludeBelowPrice(item, state, "SELL")

  assert(result == ItemFilters.PASS)
  assert(reason == nil)
end
