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

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.ProfileChanged, function()
  for list in Lists.iterate() do
    -- Update sv reference
    list._sv = list.getSvar()
    -- Clear items
    for k in pairs(list.items) do list.items[k] = nil end
    -- Queue items to add directly from sv
    for k in pairs(list._sv) do list.toAdd[k] = true end
  end
end)


-- ============================================================================
-- Create Function
-- ============================================================================

--[[
  Populates the group with required generic values and returns it.

  @param {table} group = {
    {string} locale,
    {function} itemCanBeAdded,

    {table} inclusions = {
      {table} uiGroup,
      {string} helpText,
      {function} getSvar
    },

    {table} exclusions = {
      {table} uiGroup,
      {string} helpText,
      {function} getSvar
    }
  }
--]]
local function create(group)
  group.inclusions.color = Colors.Red
  group.exclusions.color = Colors.Green

  group.inclusions.sibling = group.exclusions
  group.exclusions.sibling = group.inclusions

  group.inclusions.locale = L.OPTION_GROUP_INCLUSIONS:format(group.locale)
  group.inclusions.localeShort = L.INCLUSIONS_TEXT

  group.exclusions.locale = L.OPTION_GROUP_EXCLUSIONS:format(group.locale)
  group.exclusions.localeShort = L.EXCLUSIONS_TEXT

  -- Mixins/values
  for _, list in pairs({ group.inclusions, group.exclusions }) do
    for k, v in pairs(ListMixins) do list[k] = v end
    list.ItemCanBeAdded = group.itemCanBeAdded
    list.locale = DCL:ColorString(list.locale, list.color)
    list.localeShort = DCL:ColorString(list.localeShort, list.color)
    list.toAdd = {}
    list.items = {}
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
    helpText = L.SELL_INCLUSIONS_HELP_TEXT,
    getSvar = function()
      return DB.Profile.sell.inclusions
    end
  },

  exclusions = {
    uiGroup = UI.Groups.SellExclusions,
    helpText = L.SELL_EXCLUSIONS_HELP_TEXT,
    getSvar = function()
      return DB.Profile.sell.exclusions
    end
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
    helpText = L.DESTROY_INCLUSIONS_HELP_TEXT,
    getSvar = function()
      return DB.Profile.destroy.inclusions
    end
  },

  exclusions = {
    uiGroup = UI.Groups.DestroyExclusions,
    helpText = L.DESTROY_EXCLUSIONS_HELP_TEXT,
    getSvar = function()
      return DB.Profile.destroy.exclusions
    end
  }
})

-- ============================================================================
-- Iterator
-- ============================================================================

local _lists = {}

-- Populate `_lists`
for _, group in pairs(Lists) do
  _lists[group.inclusions] = true
  _lists[group.exclusions] = true
end

--[[ Usage:
  for list in Lists.iterate() do
    -- ...
  end
--]]
function Lists.iterate()
  return next, _lists
end
