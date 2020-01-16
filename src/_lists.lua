local _, Addon = ...
local Core = Addon.Core
local EventManager = Addon.EventManager
local GetItemInfo = _G.GetItemInfo
local L = Addon.Libs.L
local tconcat = table.concat
local Tools = Addon.Tools
local tremove = table.remove
local tsort = table.sort

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
    Core:Print(
      L.ADDED_ITEM_TO_LIST:format(
        item.ItemLink,
        Tools:GetColoredListName(list.name)
      )
    )
  end
  -- Add item
  list.items[#list.items+1] = item
  EventManager:Fire("LIST_ITEM_ADDED", list, item)
end


-- Sort function for sorting items by quality.
-- @param {table} a - item a
-- @param {table} b - item b
local function sortByQuality(a, b)
  if (a.Quality == b.Quality) then -- Sort by name
    return (a.Name < b.Name)
  else -- Sort by quality
    return (a.Quality < b.Quality)
  end
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
      Core:Print(
        L.ITEM_ALREADY_ON_LIST:format(
          itemLink,
          Tools:GetColoredListName(self.name)
        )
      )
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
        L.REMOVED_ITEM_FROM_LIST:format(
          item.ItemLink,
          Tools:GetColoredListName(self.name)
        )
      )
    end
  elseif notify then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Core:Print(
        L.ITEM_NOT_ON_LIST:format(itemLink, Tools:GetColoredListName(self.name))
      )
    end
  end
end


-- Removes all items from the list.
function List:RemoveAll()
  if next(self._sv) then
    for k in pairs(self._sv) do self._sv[k] = nil end
    for k in pairs(self.items) do self.items[k] = nil end
    Core:Print(
      L.REMOVED_ALL_FROM_LIST:format(Tools:GetColoredListName(self.name))
    )
  end
end


-- Queues many items to be added to the list by ID.
-- @param {table} itemIDs - table of item IDs to add
function List:Import(itemIDs)
  for itemID in pairs(itemIDs) do self:Add(itemID) end
end


-- Returns a comma-seperated string of all item IDs in the list.
-- @return {string}
function List:Export()
  local builder = {}
  for k in pairs(self._sv) do builder[#builder+1] = k end
  return tconcat(builder, ";")
end


-- Sorts the underlying array of items.
-- @param {string} method - "QUALITY" | "NAME" | "TYPE"
function List:Sort(method)
  -- NOTE: I will update this in a future commit.

  -- self._sortMethod = method or self._sortMethod or "QUALITY"
  -- table.sort(self.items, sortMethods[self._sortMethod])

  tsort(self.items, sortByQuality)
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

-- ============================================================================
-- Create the lists
-- ============================================================================

-- Creates a new list.
-- @param {string} name - a name for the list
local function create(name)
  local list = {
    -- _sv = table, set in "DB_PROFILE_CHANGED" event
    name = name,
    toAdd = {},
    items = {}
  }

  -- Add mixins
  for k, v in pairs(List) do list[k] = v end

  return list
end

local Lists = {
  Inclusions = true,
  Exclusions = true,
  Destroyables = true
}

for name in pairs(Lists) do
  Lists[name] = create(name)
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


function Lists.Exclusions:FinalizeAdd(item)
  if Tools:ItemCanBeSold(item) then
    finalizeAdd(self, item)
    return true
  end

  Core:Print(L.ITEM_CANNOT_BE_SOLD:format(item.ItemLink))
  return false
end


function Lists.Destroyables:FinalizeAdd(item)
  if Tools:ItemCanBeDestroyed(item) then
    finalizeAdd(self, item)
    return true
  end

  Core:Print(L.ITEM_CANNOT_BE_DESTROYED:format(item.ItemLink))
  return false
end

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

  -- Remove item from Exclusions when added to Inclusions
  if list == Lists.Inclusions then
    if Lists.Exclusions:Has(itemID) then
      Lists.Exclusions:Remove(itemID)
    end
  end

  -- Remove item from Inclusions when added to Exclusions
  if list == Lists.Exclusions then
    if Lists.Inclusions:Has(itemID) then
      Lists.Inclusions:Remove(itemID)
    end
  end
end)
