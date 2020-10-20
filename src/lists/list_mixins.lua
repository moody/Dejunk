local _, Addon = ...
local Chat = Addon.Chat
local E = Addon.Events
local EventManager = Addon.EventManager
local GetItemInfo = _G.GetItemInfo
local L = Addon.Libs.L
local ListMixins = Addon.ListMixins
local tremove = table.remove

-- ============================================================================
-- Functions
-- ============================================================================

-- Returns true if the item ID is on the list.
function ListMixins:Has(itemID)
  itemID = tostring(itemID)
  return not not self._sv[itemID]
end

-- Queues an item to be added to the list.
-- @param {string, number} itemID - the item ID to add
function ListMixins:Add(itemID)
  itemID = tostring(itemID)

  -- Don't add if already on list
  if self._sv[itemID] then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Chat:Print(L.ITEM_ALREADY_ON_LIST:format(itemLink, self.locale))
    end
  else
    self.toAdd[itemID] = true
  end
end

-- Called by `ListHelper` once a queued item has been parsed and is ready to be
-- added.
-- @param {table} item - the item to add
-- @return {boolean} - true if the item was added, false otherwise
function ListMixins:FinalizeAdd(item)
  local canBeAdded, reason = self:ItemCanBeAdded(item)

  if canBeAdded then
    -- Add to sv and print message if not loading from sv
    if not self._sv[item.ItemID] then
      self._sv[item.ItemID] = true
      Chat:Print(L.ADDED_ITEM_TO_LIST:format(item.ItemLink, self.locale))
    end

    -- Add item
    self.items[#self.items+1] = item
    EventManager:Fire(E.ListItemAdded, self, item)

    -- Remove item from sibling list
    self.sibling:Remove(item.ItemID)

    return true
  end

  Chat:Print(reason)
  return false
end

-- Removes an item from the list by ID.
-- @param {string, number} itemID - the item ID to remove
-- @param {boolean} notify - prints a message if the item is not on the list
function ListMixins:Remove(itemID, notify)
  itemID = tostring(itemID)

  if self._sv[itemID] then
    -- Remove from SVs
    self._sv[itemID] = nil
    -- Remove from sorted array
    local index = self:GetIndex(itemID)
    if index ~= -1 then
      local item = tremove(self.items, index)
      Chat:Print(
        L.REMOVED_ITEM_FROM_LIST:format(item.ItemLink, self.locale)
      )
      EventManager:Fire(E.ListItemRemoved, self, item)
    end
  elseif notify then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Chat:Print(L.ITEM_NOT_ON_LIST:format(itemLink, self.locale))
    end
  end
end

-- Removes all items from the list.
function ListMixins:RemoveAll()
  if next(self._sv) then
    for k in pairs(self._sv) do self._sv[k] = nil end
    for k in pairs(self.items) do self.items[k] = nil end
    Chat:Print(L.REMOVED_ALL_FROM_LIST:format(self.locale))
    EventManager:Fire(E.ListRemovedAll, self)
  end
end

-- Returns the index of the item if it exists in the list, and -1 otherwise.
-- @param {string, number} itemID - the item ID to search for
-- @return {number}
function ListMixins:GetIndex(itemID)
  for i, item in ipairs(self.items) do
    if item.ItemID == itemID then return i end
  end

  return -1
end

-- Returns an array containing all item IDs in the list.
-- @return {table}
function ListMixins:GetItemIDs()
  local ids = {}
  for k in pairs(self._sv) do ids[#ids+1] = k end
  return ids
end
