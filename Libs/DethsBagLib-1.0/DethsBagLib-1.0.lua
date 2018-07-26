-- https://github.com/moody/DethsBagLib-1.0

local MAJOR, MINOR = "DethsBagLib-1.0", 1

local DBL = LibStub:NewLibrary(MAJOR, MINOR)
if not DBL then return end

-- Upvalues
local assert, pairs, type, select =
      assert, pairs, type, select
local tremove = table.remove

local BACKPACK_CONTAINER, NUM_BAG_SLOTS = BACKPACK_CONTAINER, NUM_BAG_SLOTS
local GetItemInfo, GetContainerItemInfo, GetDetailedItemLevelInfo =
      GetItemInfo, GetContainerItemInfo, GetDetailedItemLevelInfo
local GetContainerNumSlots, GetContainerItemID =
      GetContainerNumSlots, GetContainerItemID

-- _DBL - private library table
local _DBL = {
  IsUpToDate = false,
  UpdateQueued = false,
  UpdateTimer = 0,
  
  Bags = {
    --[[ References to BagIndex tables should never change.
    [BagIndex] = {
      [SlotIndex] = item returned from _DBL:GetItem()
      ...
    }
    ...
    --]]
  },
  Items = {
    -- array of items returned from _DBL:GetItem()
  },
  Listeners = {
    -- [function] = true
  }
}

-- Add tables to _DBL.Bags
for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do _DBL.Bags[bag] = {} end

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Returns a shallow copy of the specified table.
-- @param t - the table to copy
-- @param copy - the table to copy into [optional]
local function tcopy(t, copy)
  if not copy then copy = _DBL:Get() end
  for k, v in pairs(t) do copy[k] = v end
  return copy
end

-- ============================================================================
-- _DBL Pooling Functions
-- ============================================================================

do
  local pool = {}

  -- Returns a table from the pool.
  function _DBL:Get()
    local t = next(pool)
    if t then pool[t] = nil else t = {} end
    return t
  end
  
  -- Releases a table into the pool.
  -- @param t - the table to release
  function _DBL:Release(t)
    self:ReleaseChildren(t)
    pool[t] = true
  end

  -- Recursively cleans a specified table and releases its child tables into the pool.
  -- @param t - the table to clean
  function _DBL:ReleaseChildren(t)
    for k, v in pairs(t) do
      if (type(v) == "table") then
        self:ReleaseChildren(v)
        pool[v] = true
      end
      t[k] = nil
    end
  end
end

-- ============================================================================
-- _DBL.BagUpdateFrame
-- ============================================================================

do
  local bagUpdateFrame = CreateFrame("Frame", MAJOR.."BagUpdateFrame")

  function bagUpdateFrame:OnEvent(event, ...)
    if (event == "BAG_UPDATE") then
      local bagID = ...
      if (bagID >= BACKPACK_CONTAINER) and (bagID <= NUM_BAG_SLOTS) then
        _DBL:QueueUpdate()
      end
    end
  end

  bagUpdateFrame:SetScript("OnEvent", bagUpdateFrame.OnEvent)
  bagUpdateFrame:RegisterEvent("BAG_UPDATE")

  function bagUpdateFrame:OnUpdate(elapsed) _DBL:OnUpdate(elapsed) end
  
  bagUpdateFrame:SetScript("OnUpdate", bagUpdateFrame.OnUpdate)
end

-- ============================================================================
-- _DBL Functions (Private)
-- ============================================================================

-- Queues DBL for updating.
function _DBL:QueueUpdate()
  self.UpdateTimer = 0
  self.UpdateQueued = true
  self.IsUpToDate = false
end

-- Called by bagUpdateFrame above.
function _DBL:OnUpdate(elapsed)
  if not self.UpdateQueued then return end

  self.UpdateTimer = self.UpdateTimer + elapsed
  if (self.UpdateTimer >= 0.5) then -- 1/2 second delay
    if self:VerifyCache() then
      self.UpdateTimer = 0
      self.UpdateQueued = false
      self:UpdateItems()
    end
  end
end

do -- _DBL:VerifyCache()
  local RETRIEVING_ITEM_INFO = RETRIEVING_ITEM_INFO
  local itemID, link, name

  -- Returns true if all items in the player's bags have info available.
  function _DBL:VerifyCache()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
      for slot = 1, GetContainerNumSlots(bag) do
        itemID = GetContainerItemID(bag, slot)
        if itemID then -- slot is not empty
          --[[
            NOTE: Mythic keystones and battle pets use a different type of item
            link than all other items. These links cause GetItemInfo(link) to
            return empty. When this happens, we fall back to using
            GetItemInfo(itemID).
          ]]
          link = GetContainerItemLink(bag, slot)
          name = link and GetItemInfo(link) or GetItemInfo(itemID)
          if not name or (name == RETRIEVING_ITEM_INFO) then return false end
        end
      end
    end

    return true
  end
end

-- Updates the _DBL.Bags and _DBL.Items tables.
function _DBL:UpdateItems()
  -- Clear bags
  for _, bag in pairs(self.Bags) do
    for k in pairs(bag) do bag[k] = nil end
  end
  -- Clear items
  self:ReleaseChildren(self.Items)

  -- Build bag and item tables
  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      if GetContainerItemID(bag, slot) then -- slot is not empty
        local item = self:GetItem(bag, slot)
        if item then
          self.Bags[bag][slot] = item
          self.Items[#self.Items+1] = item
        else
          self:QueueUpdate()
          return
        end
      end
    end
  end

  self.IsUpToDate = true
  
  -- Notify listeners
  for listener in pairs(self.Listeners) do listener() end
end

do -- _DBL:GetItem()
  local function isLocked(self)
    return select(3, GetContainerItemInfo(self.Bag, self.Slot))
  end

  local function isFiltered(self)
    return select(8, GetContainerItemInfo(self.Bag, self.Slot))
  end

  -- Returns a table of item info for the item residing within a specified bag
  -- and slot, or nil if the info could not be retrieved.
  function _DBL:GetItem(bag, slot)
    -- Get item info, return nil if missing info
    -- Ignoring: locked (3), filtered (7)
    local texture, quantity, _, quality, readable, lootable, itemLink, _, noValue, itemID = GetContainerItemInfo(bag, slot)
    if not (texture and quantity and quality and (readable ~= nil) and
    (lootable ~= nil) and itemLink and (noValue ~= nil) and itemID) then
      return nil
    end

    -- Get additional item info, return nil if missing info
    -- Ignoring: itemLink (2), quality (3), itemLevel (4), texture (10)
    local name, _, _, _, reqLevel, class, subClass, maxStack, equipSlot, _, price, classID, subClassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemLink)
    if not name then name, _, _, _, reqLevel, class, subClass, maxStack, equipSlot, _, price, classID, subClassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemID) end
    if not (name and reqLevel and class and subClass and maxStack and equipSlot and price and classID and subClassID and bindType and expacID) then return nil end

    -- Item level, passing itemLink is most accurate since it supports upgraded items
    local itemLevel = GetDetailedItemLevelInfo(itemLink) or GetDetailedItemLevelInfo(itemID) or 1
    
    -- Build and return item
    local item = self:Get()
    item.Bag = bag
    item.Slot = slot

    -- Functions
    item.IsFiltered = isFiltered
    item.IsLocked = isLocked

    -- GetContainerItemInfo
    item.Texture = texture
    item.Quantity = quantity
    item.Quality = quality
    item.Readable = readable
    item.Lootable = lootable
    item.ItemLink = itemLink
    item.NoValue = noValue
    item.ItemID = itemID

    -- GetItemInfo
    item.Name = name
    item.RequiredLevel = reqLevel
    item.Class = class
    item.SubClass = subClass
    item.MaxStack = maxStack
    item.EquipSlot = equipSlot
    item.Price = price
    item.ClassID = classID
    item.SubClassID = subClassID
    item.BindType = bindType
    item.ExpacID = expacID
    item.SetID = setID
    item.IsCraftingReagent = isCraftingReagent
    
    -- GetDetailedItemLevelInfo
    item.ItemLevel = itemLevel

    return item
  end
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Registers a function to be called each time DBL fully updates.
-- @param listener - the listener function to add
function DBL:AddListener(listener)
  assert(type(listener) == "function", "listener must be a function")
  _DBL.Listeners[listener] = true
end

-- Removes a listener by reference.
-- @param listener - the listener function to remove
function DBL:RemoveListener(listener)
  if _DBL.Listeners[listener] then _DBL.Listeners[listener] = nil end
end

-- Returns true if all items are available and up-to-date.
function DBL:IsUpToDate()
  return _DBL.IsUpToDate
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
  local _, quantity, _, _, _, _, itemLink, _, _, _ = GetContainerItemInfo(item.Bag, item.Slot)
  return (item.Quantity == quantity) and (item.ItemLink == itemLink)
end

-- Returns true if two items are identical.
-- @param item1 - the first item
-- @param item2 - the second item
function DBL:Compare(item1, item2)
  for k, v in pairs(item1) do
    if not (item2[k] == v) then
      return false
    end
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
    if not filterFunc(items[i]) then
      _DBL:Release(tremove(items, i))
    end
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
  local item = _DBL.Bags[bag] and _DBL.Bags[bag][slot]
  if not item then return nil end

  if t and (type(t) == "table") then
    _DBL:ReleaseChildren(t)
    return tcopy(item, t)
  else
    return tcopy(item)
  end
end

-- This function returns either a new table with all up-to-date items, or the
-- specified table after cleaning and coping items into it.
-- @param t - the table to copy items into [optional]
function DBL:GetItems(t)
  -- Initialize t
  if t and (type(t) == "table") then
    _DBL:ReleaseChildren(t)
  else
    t = _DBL:Get()
  end

  -- Copy
  for i, item in pairs(_DBL.Items) do
    t[i] = tcopy(item)
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
    assert((type(maxItems) == "number") and (maxItems > 0), "maxItems must be a number > 0")
  end

  -- Initialize t
  if t and (type(t) == "table") then
    _DBL:ReleaseChildren(t)
  else
    t = _DBL:Get()
  end

  -- Copy
  for i, item in pairs(_DBL.Items) do
    if filterFunc(item) then -- copy item into t
      t[#t+1] = tcopy(item)
    end

    if maxItems and (#t >= maxItems) then return t end
  end

  return t
end
