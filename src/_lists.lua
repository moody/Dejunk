local _, Addon = ...
local Colors = Addon.Colors
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local EventManager = Addon.EventManager
local GetItemInfo = _G.GetItemInfo
local L = Addon.Libs.L
local Tools = Addon.Tools
local tremove = table.remove

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Adds an item to the specified list and prints a message if necessary.
-- @param {table} list - the target list
-- @param {table} item - the item to add
local function finalizeAdd(list, item)
  -- Add to sv and print message if not loading from sv
  if not list._sv[item.ItemID] then
    list._sv[item.ItemID] = true
    Core:Print(L.ADDED_ITEM_TO_LIST:format(item.ItemLink, list.localeColored))
  end
  -- Add item
  list.items[#list.items+1] = item
  EventManager:Fire("LIST_ITEM_ADDED", list, item)
end

-- ============================================================================
-- List
-- ============================================================================

local List = {}

-- Returns true if the item ID is on the list.
function List:Has(itemID)
  itemID = tostring(itemID)
  return not not self._sv[itemID]
end

-- Queues an item to be added to the list.
-- @param {string, number} itemID - the item ID to add
function List:Add(itemID)
  itemID = tostring(itemID)

  -- Don't add if already on list
  if self._sv[itemID] then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Core:Print(L.ITEM_ALREADY_ON_LIST:format(itemLink, self.localeColored))
    end
  else
    self.toAdd[itemID] = true
  end
end

-- Called by `ListHelper` once a queued item has been parsed and is ready to be
-- added. Override as necessary to validate items before they are added.
-- @param {table} item - the item to add
-- @return {boolean} - true if the item was added, false otherwise
function List:FinalizeAdd(item)
  finalizeAdd(self, item)
  return true
end

-- Removes an item from the list by ID.
-- @param {string, number} itemID - the item ID to remove
-- @param {boolean} notify - prints a message if the item is not on the list
function List:Remove(itemID, notify)
  itemID = tostring(itemID)

  if self._sv[itemID] then
    -- Remove from SVs
    self._sv[itemID] = nil
    -- Remove from sorted array
    local index = self:GetIndex(itemID)
    if index ~= -1 then
      local item = tremove(self.items, index)
      Core:Print(
        L.REMOVED_ITEM_FROM_LIST:format(item.ItemLink, self.localeColored)
      )
    end
  elseif notify then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Core:Print(L.ITEM_NOT_ON_LIST:format(itemLink, self.localeColored))
    end
  end
end

-- Removes all items from the list.
function List:RemoveAll()
  if next(self._sv) then
    for k in pairs(self._sv) do self._sv[k] = nil end
    for k in pairs(self.items) do self.items[k] = nil end
    Core:Print(L.REMOVED_ALL_FROM_LIST:format(self.localeColored))
  end
end

-- Returns the index of the item if it exists in the list, and -1 otherwise.
-- @param {string, number} itemID - the item ID to search for
-- @return {number}
function List:GetIndex(itemID)
  for i, item in ipairs(self.items) do
    if item.ItemID == itemID then return i end
  end

  return -1
end

-- Returns an array containing all item IDs in the list.
-- @return {table}
function List:GetItemIDs()
  local ids = {}
  for k in pairs(self._sv) do ids[#ids+1] = k end
  return ids
end

-- ============================================================================
-- Create the lists
-- ============================================================================

--[[
  Creates a new list.

  @param {string} name - non-localized name of the list
  @param {table} options = {
    {string} locale - localized name of the list
    {string} color - hex color of the list
  }

  @return {table}
--]]
local function create(name, options)
  local list = {
    -- _sv = table, set in "DB_PROFILE_CHANGED" event

    name = name,
    color = options.color,
    locale = options.locale,
    localeColored = DCL:ColorString(options.locale, options.color),

    toAdd = {},
    items = {}
  }

  -- Add mixins
  for k, v in pairs(List) do list[k] = v end

  return list
end

local Lists = {
  Inclusions = { locale = L.INCLUSIONS_TEXT, color = Colors.Red },
  Exclusions = { locale = L.EXCLUSIONS_TEXT, color = Colors.Green },
  Destroyables = { locale = L.DESTROYABLES_TEXT, color = Colors.Red },
  Undestroyables = { locale = L.UNDESTROYABLES_TEXT, color = Colors.Green }
}

for name, options in pairs(Lists) do
  Lists[name] = create(name, options)
end

Addon.Lists = Lists

-- ============================================================================
-- List:FinalizeAdd() Overrides
-- ============================================================================

function Lists.Inclusions:FinalizeAdd(item)
  if Tools:ItemCanBeSold(item) then
    finalizeAdd(self, item)
    return true
  end

  Core:Print(L.ITEM_CANNOT_BE_SOLD:format(item.ItemLink))
  return false
end
Lists.Exclusions.FinalizeAdd = Lists.Inclusions.FinalizeAdd

function Lists.Destroyables:FinalizeAdd(item)
  if Tools:ItemCanBeDestroyed(item) then
    finalizeAdd(self, item)
    return true
  end

  Core:Print(L.ITEM_CANNOT_BE_DESTROYED:format(item.ItemLink))
  return false
end
Lists.Undestroyables.FinalizeAdd = Lists.Destroyables.FinalizeAdd

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On("DB_PROFILE_CHANGED", function()
  for name, list in pairs(Lists) do
    -- Update variables
    list._sv = Addon.DB.Profile[name] or error("Unsupported list name: "..name)
    for k in pairs(list.items) do list.items[k] = nil end
    -- Queue items to add directly from sv
    for k in pairs(list._sv) do list.toAdd[k] = true end
  end
end)

EventManager:On("LIST_ITEM_ADDED", function(list, item)
  local itemID = item.ItemID

  -- Remove from Exclusions when added to Inclusions and vice versa
  if list == Lists.Inclusions then Lists.Exclusions:Remove(itemID) end
  if list == Lists.Exclusions then Lists.Inclusions:Remove(itemID) end

  -- Remove from Undestroyables when added to Destroyables and vice versa
  if list == Lists.Destroyables then Lists.Undestroyables:Remove(itemID) end
  if list == Lists.Undestroyables then Lists.Destroyables:Remove(itemID) end
end)
