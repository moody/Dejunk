-- ListManager: manages the Inclusions, Exclusions, and Destroyables lists in the saved variables.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL

-- Upvalues
local assert, pairs, next = assert, pairs, next
local tremove, sort, concat = table.remove, table.sort, table.concat
local format, select, tonumber, tostring = format, select, tonumber, tostring

local GetItemInfo, GetItemInfoInstant = GetItemInfo, GetItemInfoInstant

-- Modules
local ListManager = Addon.ListManager
ListManager.Lists = {
  ["Inclusions"] = {},
  ["Exclusions"] = {},
  ["Destroyables"] = {}
  -- ["ListName"] = array of item tables
}
ListManager.ToAdd = {}
ListManager.ToRemove = {}
-- Add list keys to ToAdd and ToRemove
for k in pairs(ListManager.Lists) do
  ListManager.ToAdd[k] = {}
  ListManager.ToRemove[k] = {}
end

local Core = Addon.Core
local Colors = Addon.Colors
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local Tools = Addon.Tools
local DB = Addon.DB

-- Consts
local MAX_NUMBER = 2147483647 -- 32-bit signed

-- ============================================================================
-- General Functions
-- ============================================================================

-- Initializes the ListManager.
function ListManager:Initialize()
  self:Update()
  self.Initialize = nil
end

-- Updates the ListManager's references to lists in the saved variables.
function ListManager:Update()
  -- Clear item lists
  for _, list in pairs(self.Lists) do
    for k in pairs(list) do list[k] = nil end
  end

  -- Load lists' items
  for listName, toAdd in pairs(self.ToAdd) do
    for itemID in pairs(self:GetListSV(listName)) do
      toAdd[itemID] = true
    end
  end
end

-- Checks whether the ListManager is currently parsing a specific list or in general.
-- @param listName - name of the list to check [optional]
-- @return - boolean
function ListManager:IsParsing(listName)
  if listName then -- parsing specific list?
    return (next(self.ToAdd[listName]) or next(self.ToRemove[listName]))
  else -- parsing in general?
    for k in pairs(self.Lists) do
      if (next(self.ToAdd[k]) or next(self.ToRemove[k])) then return true end
    end
  end

  return false
end

-- Gets a list from saved variables.
-- @param listName - the name of the list to get SVs
function ListManager:GetListSV(listName)
  assert(self.Lists[listName])
  return DB.Profile[listName]
end

-- Returns list data for use in ListManager functions.
function ListManager:GetListData(listName)
  assert(self.Lists[listName])

  local list = self.Lists[listName]
  local toAdd = self.ToAdd[listName]
  local toRemove = self.ToRemove[listName]
  local sv = self:GetListSV(listName)
  local coloredName = Tools:GetColoredListName(listName)

  local otherListName = nil
  if (listName == "Inclusions") then
    otherListName = "Exclusions"
  elseif (listName == "Exclusions") then
    otherListName = "Inclusions"
  end

  return list, toAdd, toRemove, sv, coloredName, otherListName
end

-- ============================================================================
-- List Functions
-- ============================================================================

-- Adds an item to the specified list.
-- @param listName - the name of the list to add to
-- @param itemID - the item id of the item to add
function ListManager:AddToList(listName, itemID)
  assert(self.Lists[listName] ~= nil)
  itemID = tostring(itemID)

  -- Initialize data
  local _, toAdd, _, _, coloredName, otherListName = self:GetListData(listName)

  -- Don't add if the item is already being parsed
  if toAdd[itemID] then return end

  -- Don't add if the item is already on the list
  if self:IsOnList(listName, itemID) then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Core:Print(format(L.ITEM_ALREADY_ON_LIST, itemLink, coloredName)) end
    return
  end

  -- If the item is on the other list, remove it first
  if otherListName then self:RemoveFromList(otherListName, itemID) end

  -- Finally, add the item for parsing
  toAdd[itemID] = true
end

-- Removes an item from the specified list.
-- @param listName - the name of the list to remove from
-- @param itemID - the item id of the item to remove
-- @param notify - if true, prints a message if the item is not on the list
function ListManager:RemoveFromList(listName, itemID, notify)
  assert(self.Lists[listName] ~= nil)
  itemID = tostring(itemID)

  if self:IsOnList(listName, itemID) then
    self.ToRemove[listName][itemID] = true
  elseif notify then
    local itemLink = select(2, GetItemInfo(itemID))
    if itemLink then
      Core:Print(format(L.ITEM_NOT_ON_LIST, itemLink,
        Tools:GetColoredListName(listName)))
    end
  end
end

-- Checks whether or not an item exists in the specified list.
-- @param listName - the name of the list to search
-- @param itemID - the item id of the item to search for
-- @return - boolean
function ListManager:IsOnList(listName, itemID)
  assert(self.Lists[listName] ~= nil)
  itemID = tostring(itemID)

  return self:GetListSV(listName)[itemID]
end

-- Removes all entries from the specified list.
-- @param listName - the name of the list to destroy
function ListManager:DestroyList(listName)
  assert(self.Lists[listName] ~= nil)

  -- Initialize data
  local list, _, _, sv, coloredName = self:GetListData(listName)

  if not (#list > 0) then return end
  for k in pairs(list) do list[k] = nil end
  for k in pairs(sv) do sv[k] = nil end

  Core:Print(format(L.REMOVED_ALL_FROM_LIST, coloredName))
end

-- ============================================================================
-- Transport Functions
-- ============================================================================

-- Parses an import string for item IDs to add to the specified list.
-- @param listName - the name of the list to import into
-- @param string - the import string with format: "itemID;itemID;itemID;"
function ListManager:ImportToList(listName, string)
  assert(self.Lists[listName] ~= nil)

  for itemID in string:gmatch('([^;]+)') do
    itemID = tonumber(itemID)
    if (itemID and (itemID > 0) and (itemID <= MAX_NUMBER)) then
      self:AddToList(listName, itemID)
    end
  end
end

-- Creates and returns a string containing all item IDs on the specified list.
-- @param listName - the name of the list to export
-- @return - a string with format: "itemID;itemID;itemID;"
function ListManager:ExportFromList(listName)
  assert(self.Lists[listName] ~= nil)

  -- Initialize data
  local sv = self:GetListSV(listName)
  local itemIDs = {}

  for k in pairs(sv) do
    itemIDs[#itemIDs+1] = k
  end

  return concat(itemIDs, ";")
end

-- ============================================================================
-- Parsing Functions
-- ============================================================================

do -- OnUpdate(), called in Core:OnUpdate()
  local interval = 0

  function ListManager:OnUpdate(elapsed)
    if Dejunker:IsDejunking() or Destroyer:IsDestroying() then return end
    
    -- Removals
    for listName, list in pairs(self.ToRemove) do
      if next(list) then self:CleanList(listName) end
    end
    
    -- Additions
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0
      for listName, list in pairs(self.ToAdd) do
        if next(list) then self:ParseList(listName) end
      end
    end
  end
end

do -- CleanList()
  -- Removes an item from the specified list by ID.
  local function removeItem(list, itemID, sv, coloredName)
    for k, v in pairs(list) do
      if (v.ItemID == itemID) then
        tremove(list, k) -- tremove has to be used here for the table to update as expected
        sv[itemID] = nil
        Core:Print(format(L.REMOVED_ITEM_FROM_LIST, v.ItemLink, coloredName))
        return
      end
    end
  end

  -- Cleans the specified list by removing queued entries.
  -- @param listName - the name of the list to clean
  function ListManager:CleanList(listName)
    assert(self.Lists[listName])

    -- Initialize data
    local list, _, toRemove, sv, coloredName = self:GetListData(listName)

    -- Remove up to 500 items each update
    for i=1, 500 do
      local itemID = next(toRemove)
      if not itemID then return end
      removeItem(list, itemID, sv, coloredName)
      toRemove[itemID] = nil
    end
  end
end

do -- ParseList()
  local MAX_PARSE_ATTEMPTS = 50
  local parseAttempts = {
    -- [itemID] = count
  }
  
  -- Creates and returns an item by item id.
  -- @param itemID - the item id of the item to create
  -- @return - a table with item data
  local function getItemByID(itemID)
    local name, itemLink, quality, _, _, class, _, _, _, texture, price = GetItemInfo(itemID)
    if not (name and itemLink and quality and class and texture and price) then return nil end

    return {
      ItemID = itemID,
      Name = name,
      ItemLink = itemLink,
      Quality = quality,
      Class = class,
      Texture = texture,
      Price = price
    }
  end

  -- Returns true if the item can be sold, and the target list is Inclusions or Exclusions.
  local function canBeSold(listName, item)
    if not (listName == "Inclusions" or listName == "Exclusions") then return false end
    if Tools:ItemCanBeSold(item) then return true end
    Core:Print(format(L.ITEM_CANNOT_BE_SOLD, item.ItemLink))
    return false
  end

  -- Returns true if the item can be destroyed, and the target list is Destroyables.
  local function canBeDestroyed(listName, item)
    if not (listName == "Destroyables") then return false end
    if Tools:ItemCanBeDestroyed(item) then return true end
    Core:Print(format(L.ITEM_CANNOT_BE_DESTROYED, item.ItemLink))
    return false
  end

  -- Sort function to be passed into table.sort(table, function).
  local function item_sort(a, b)
    if (a.Quality == b.Quality) then -- Sort by name
      return (a.Name < b.Name)
    else -- Sort by quality
      return (a.Quality < b.Quality)
    end
  end

  -- Parses queued itemIDs and adds them to the specified list.
  -- @param listName - the name of the list to parse
  function ListManager:ParseList(listName)
    assert(self.Lists[listName])

    -- Initialize data
    local list, toAdd, _, sv, coloredName = self:GetListData(listName)

    -- Parse items
    for itemID in pairs(toAdd) do
      -- Instantly fail if item doesn't exist
      if not GetItemInfoInstant(itemID) then
        sv[itemID] = nil -- remove from sv
        toAdd[itemID] = nil -- remove from parsing
        Core:Print(format(L.FAILED_TO_PARSE_ITEM_ID, DCL:ColorString(itemID, DCL.CSS.Grey)))
      else
        -- Attempt to parse the item
        local item = getItemByID(itemID)
        if item then
          -- Add item if it can be sold or destroyed
          if (canBeSold(listName, item) or canBeDestroyed(listName, item)) then
            -- Add to sv and print message if not loading from sv
            if not sv[itemID] then
              sv[itemID] = true -- add to sv
              Core:Print(format(L.ADDED_ITEM_TO_LIST, item.ItemLink, coloredName))
            end
            -- Add item table to list
            list[#list+1] = item
          else
            -- Remove from sv since item cannot be added
            sv[itemID] = nil
          end
          -- Remove from parsing
          parseAttempts[itemID] = nil
          toAdd[itemID] = nil
        else
          -- Retry parsing until max attempts reached
          local attempts = (parseAttempts[itemID] or 0) + 1
          if (attempts >= MAX_PARSE_ATTEMPTS) then
            parseAttempts[itemID] = nil
            sv[itemID] = nil -- remove from sv
            toAdd[itemID] = nil -- remove from parsing
            Core:Print(format(L.FAILED_TO_PARSE_ITEM_ID, DCL:ColorString(itemID, DCL.CSS.Grey)))
          else
            parseAttempts[itemID] = attempts
          end
        end
      end
    end

    -- Sort the list once all items have been parsed
    if not next(toAdd) then
      sort(list, item_sort)

      -- Start auto destroy if the Destroyables list was updated
      if (listName == "Destroyables") then Destroyer:StartAutoDestroy() end
    end
  end
end
