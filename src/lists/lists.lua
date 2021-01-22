local _, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Libs.L
local ListMixins = Addon.ListMixins
local Lists = Addon.Lists
local Utils = Addon.Utils
local UI = Addon.UI

local GROUP_KEYS = {
  inclusions = "exclusions",
  exclusions = "inclusions",
}

local LIST_KEYS = { "global", "profile" }

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.DatabaseReady, function()
  for list in Lists.globalLists() do
    -- Set sv reference.
    list._sv = list.getSvar()
    -- Queue items to add directly from sv.
    for k in pairs(list._sv) do list.toAdd[k] = true end
  end
end)

EventManager:On(E.ProfileChanged, function()
  for list in Lists.profileLists() do
    -- Update sv reference
    list._sv = list.getSvar()
    -- Clear items
    for k in pairs(list.items) do list.items[k] = nil end
    -- Queue items to add directly from sv
    for k in pairs(list._sv) do list.toAdd[k] = true end
  end
end)

-- ============================================================================
-- Local Functions
-- ============================================================================

local function getLocales(groupKey, listKey)
  local suffix = DCL:ColorString(
    (listKey == "global" and L.GLOBAL_TEXT or L.PROFILE_TEXT),
    "FFFFFF"
  )

  local locale = ("%s (%s)"):format(
    (
      groupKey == "inclusions" and
      L.OPTION_GROUP_INCLUSIONS or
      L.OPTION_GROUP_EXCLUSIONS
    ),
    suffix
  )

  local shortLocale = ("%s (%s)"):format(
    (
      groupKey == "inclusions" and
      L.INCLUSIONS_TEXT or
      L.EXCLUSIONS_TEXT
    ),
    suffix
  )

  return locale, shortLocale
end

--[[
  Populates the group with required generic values and returns it.

  @param {table} group = {
    locale = string,
    itemCanBeAdded = function(self, item) -> bool,

    inclusions = {
      uiGroup = table,
      global = {
        helpText = string,
        getSvar = function() -> table
      },
      profile = {
        helpText = string,
        getSvar = function() -> table
      },
    },

    exclusions = {
      uiGroup = table,
      global = {
        helpText = string,
        getSvar = function() -> table
      },
      profile = {
        helpText = string,
        getSvar = function() -> table
      },
    }
  }
--]]
local function create(group)
  group.inclusions.color = Colors.Red
  group.exclusions.color = Colors.Green

  for groupKey, siblingKey in pairs(GROUP_KEYS) do
    for _, listKey in pairs(LIST_KEYS) do
      local color = group[groupKey].color
      local list = group[groupKey][listKey]

      -- Add fields.
      list.color = color
      list.sibling = group[siblingKey][listKey]

      list.toAdd = {}
      list.items = {}

      local locale, shortLocale = getLocales(groupKey, listKey)
      list.locale = DCL:ColorString(locale:format(group.locale), color)
      list.localeShort = DCL:ColorString(shortLocale, color)

      -- Add mixins.
      for k, v in pairs(ListMixins) do list[k] = v end
      list.ItemCanBeAdded = group.itemCanBeAdded
    end
  end

  return group
end

-- ============================================================================
-- Sell
-- ============================================================================

Lists.sell = create({
  locale = L.SELL_TEXT,

  itemCanBeAdded = function(self, item)
    if not Utils:ItemCanBeSold(item) then
      return false, L.ITEM_CANNOT_BE_SOLD:format(item.ItemLink)
    end
    return true
  end,

  inclusions = {
    uiGroup = UI.Groups.SellInclusions,
    global = {
      helpText = L.SELL_INCLUSIONS_GLOBAL_HELP_TEXT,
      getSvar = function() return DB.Global.sell.inclusions end
    },
    profile = {
      helpText = L.SELL_INCLUSIONS_HELP_TEXT,
      getSvar = function() return DB.Profile.sell.inclusions end
    },
  },

  exclusions = {
    uiGroup = UI.Groups.SellExclusions,
    global = {
      helpText = L.SELL_EXCLUSIONS_GLOBAL_HELP_TEXT,
      getSvar = function() return DB.Global.sell.exclusions end
    },
    profile = {
      helpText = L.SELL_EXCLUSIONS_HELP_TEXT,
      getSvar = function() return DB.Profile.sell.exclusions end
    },
  }
})

-- ============================================================================
-- Destroy
-- ============================================================================

Lists.destroy = create({
  locale = L.DESTROY_TEXT,

  itemCanBeAdded = function(self, item)
    if not Utils:ItemCanBeDestroyed(item) then
      return false, L.ITEM_CANNOT_BE_DESTROYED:format(item.ItemLink)
    end
    return true
  end,

  inclusions = {
    uiGroup = UI.Groups.DestroyInclusions,
    global = {
      helpText = L.DESTROY_INCLUSIONS_GLOBAL_HELP_TEXT,
      getSvar = function() return DB.Global.destroy.inclusions end
    },
    profile = {
      helpText = L.DESTROY_INCLUSIONS_HELP_TEXT,
      getSvar = function() return DB.Profile.destroy.inclusions end
    },
  },

  exclusions = {
    uiGroup = UI.Groups.DestroyExclusions,
    global = {
      helpText = L.DESTROY_EXCLUSIONS_GLOBAL_HELP_TEXT,
      getSvar = function() return DB.Global.destroy.exclusions end
    },
    profile = {
      helpText = L.DESTROY_EXCLUSIONS_HELP_TEXT,
      getSvar = function() return DB.Profile.destroy.exclusions end
    },
  }
})

-- ============================================================================
-- Iterators
-- ============================================================================

local _listGroups = {}
local _globalLists = {}
local _profileLists = {}
local _allLists = {}

-- Populate tables.
for _, group in pairs(Lists) do
  for groupKey in pairs(GROUP_KEYS) do
    local listGroup = group[groupKey]
    _listGroups[listGroup] = true
    _globalLists[listGroup.global] = true
    _profileLists[listGroup.profile] = true
    for _, listKey in pairs(LIST_KEYS) do
      _allLists[listGroup[listKey]] = true
    end
  end
end

-- Set key consts.
Lists.GROUP_KEYS = GROUP_KEYS
Lists.LIST_KEYS = LIST_KEYS

--[[ Usage:
  for listGroup in Lists.listGroups() do
    -- ...
  end
]]
function Lists.listGroups()
  return next, _listGroups
end

--[[ Usage:
  for list in Lists.globalLists() do
    -- ...
  end
--]]
function Lists.globalLists()
  return next, _globalLists
end

--[[ Usage:
  for list in Lists.profileLists() do
    -- ...
  end
--]]
function Lists.profileLists()
  return next, _profileLists
end

--[[ Usage:
  for list in Lists.allLists() do
    -- ...
  end
]]
function Lists.allLists()
  return next, _allLists
end
