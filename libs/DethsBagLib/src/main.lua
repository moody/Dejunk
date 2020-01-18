local _, Addon = ...
local DBL = Addon.DethsBagLib
if DBL.__loaded then return end

local assert = assert
local Backend = DBL.Backend
local GetContainerItemID = _G.GetContainerItemID
local GetContainerItemInfo = _G.GetContainerItemInfo
local pairs = pairs
local tremove = table.remove
local type = type

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Removes all entries from a table.
-- @param {table} t
local function tclean(t)
  for k in pairs(t) do t[k] = nil end
end

-- Returns a shallow copy of the specified table.
-- @param t - the table to copy
-- @param copy - the table to copy into [optional]
local function tcopy(t, copy)
  if type(copy) == "table" then tclean(copy) else copy = {} end
  for k, v in pairs(t) do copy[k] = v end
  return copy
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Registers a function to be called each time DBL fully updates.
-- @param listener - the listener function to add
function DBL:AddListener(listener)
  assert(type(listener) == "function", "listener must be a function")
  Backend.Listeners[listener] = true
end

-- Removes a listener by reference.
-- @param listener - the listener function to remove
function DBL:RemoveListener(listener)
  if Backend.Listeners[listener] then Backend.Listeners[listener] = nil end
end

-- Returns true if all items are available and up-to-date.
function DBL:IsUpToDate()
  return Backend.IsUpToDate
end

-- Returns true if the specified bag and slot does not contain an item.
-- @param bag - the bag index
-- @param slot - the slot index
function DBL:IsEmpty(bag, slot)
  return (GetContainerItemID(bag, slot) == nil)
end

-- Returns true if the specified item still resides in its associated bag slot.
-- @param item - the item
function DBL:StillInBags(item)
  local _, quantity, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(item.Bag, item.Slot)
  return (item.ItemID == itemID) and (item.Quantity == quantity)
end

-- Returns true if two items are identical.
-- @param item1 - the first item
-- @param item2 - the second item
function DBL:Compare(item1, item2)
  for k, v in pairs(item1) do
    if not (item2[k] == v) then return false end
  end

  return true
end

-- ============================================================================
-- Item Functions
-- ============================================================================

-- Filters the specified item table using a specified filter function.
-- A filter function takes an item as a parameter and returns true or false.
-- Only items which cause the function to return true will remain in the table.
-- @param items - the table of items to filter
-- @param filterFunc - the filter function
function DBL:FilterItems(items, filterFunc)
  assert(type(filterFunc) == "function", "filterFunc must be a function")

  for i = #items, 1, -1 do
    if not filterFunc(items[i]) then tremove(items, i) end
  end
end

--[[
  This function returns one of the following:
    1. nil if the specified bag slot is empty
    2. The specified table after cleaning and coping item data into it
    3. A new table with up-to-date item data

  @param bag - the bag index
  @param slot - the slot index
  @param t - the table to copy item data into [optional]
]]
function DBL:GetItem(bag, slot, t)
  -- Verify item exists
  local item = Backend.Bags[bag] and Backend.Bags[bag][slot]
  if not item then return nil end
  return tcopy(item, t)
end

-- This function returns either a new table with all up-to-date items, or the
-- specified table after cleaning and coping items into it.
-- @param t - the table to copy items into [optional]
function DBL:GetItems(t)
  if type(t) == "table" then tclean(t) else t = {} end

  -- Copy
  for _, bag in pairs(Backend.Bags) do
    for _, item in pairs(bag) do t[#t+1] = tcopy(item) end
  end

  return t
end

--[[
  This function is similar to DBL:GetItems(); however, the returned table will
  only contain items which cause a specified filter function to return true.

  Example filter function:
    local function filter(item)
      return item.Quality == LE_ITEM_QUALITY_POOR
    end

  @param filterFunc - the filter function
  @param t - the table to copy items into [optional]
  @param maxItems - the maximum number of items to copy [optional]
]]
function DBL:GetItemsByFilter(filterFunc, t, maxItems)
  assert(type(filterFunc) == "function", "filterFunc must be a function")

  if maxItems then
    assert(
      (type(maxItems) == "number") and (maxItems > 0),
      "maxItems must be a number > 0"
    )
  end

  if type(t) == "table" then tclean(t) else t = {} end

  -- Copy
  for _, bag in pairs(Backend.Bags) do
    for _, item in pairs(bag) do
      if filterFunc(item) then t[#t+1] = tcopy(item) end
      if maxItems and (#t >= maxItems) then return t end
    end
  end

  return t
end
