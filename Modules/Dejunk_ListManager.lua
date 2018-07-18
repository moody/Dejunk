-- Dejunk_ListManager: manages the Inclusions, Exclusions, and Destroyables lists in the saved variables.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local assert, pairs, next = assert, pairs, next
local remove, sort, concat = table.remove, table.sort, table.concat
local tonumber, tostring = tonumber, tostring

-- Dejunk
local ListManager = DJ.ListManager

local Core = DJ.Core
local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB

-- Variables
ListManager.Initialized = false

ListManager.Lists =
{
  ["Inclusions"] = {},
  ["Exclusions"] = {},
  ["Destroyables"] = {}

  -- ["ListName"] = array of items returned via Tools:GetItemByID()
}

ListManager.ToAdd = {}
ListManager.ToRemove = {}

-- Add list keys to ListManager, ToAdd, and ToRemove
for k in pairs(ListManager.Lists) do
  ListManager[k] = k
  ListManager.ToAdd[k] = {}
  ListManager.ToRemove[k] = {}
end

-- Parsing Frame
local parseFrame = CreateFrame("Frame", AddonName.."ListManagerParseFrame")
parseFrame.AttemptsToParse = {} -- Format: ["itemID"] = numOfAttemptsToParse

-- ============================================================================
--                                 LM Functions
-- ============================================================================

-- Initializes the ListManager.
function ListManager:Initialize()
  if self.Initialized then return end

  self:Update()

  self.Initialized = true
end

-- Updates the ListManager's references to lists in the saved variables.
function ListManager:Update()
  -- Clear item lists
  for k, v in pairs(self.Lists) do
    for i in pairs(v) do v[i] = nil end
  end

  -- Load lists' items
  for k, v in pairs(self.ToAdd) do
    for itemID in pairs(self:GetListSV(k)) do
      v[itemID] = true
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
  assert(self[listName])
  return DejunkDB.SV[listName]
end

-- Gets a table of list data for use in ListManager functions.
function ListManager:GetListData(listName)
  assert(self[listName])

  local list = self.Lists[listName]
  local toAdd = self.ToAdd[listName]
  local toRemove = self.ToRemove[listName]
  local sv = self:GetListSV(listName)
  local coloredName = Tools:GetColoredListName(listName)

  local otherListName = nil
  if (listName == self.Inclusions) then
    otherListName = self.Exclusions
  elseif (listName == self.Exclusions) then
    otherListName = self.Inclusions
  end

  return
  {
    List = list,
    ToAdd = toAdd,
    ToRemove = toRemove,
    SV = sv,
    OtherListName = otherListName,
    ColoredName = coloredName,
  }
end

-- ============================================================================
--                               List Functions
-- ============================================================================

-- Adds an item to the specified list.
-- @param listName - the name of the list to add to
-- @param itemID - the item id of the item to add
function ListManager:AddToList(listName, itemID)
  assert(self[listName] ~= nil)
  itemID = tostring(itemID)

  -- Initialize data
  local listData = self:GetListData(listName)
  local toAdd = listData.ToAdd
  local coloredName = listData.ColoredName
  local otherListName = listData.OtherListName
  local sv = listData.SV

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
  assert(self[listName] ~= nil)
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
  assert(self[listName] ~= nil)
  itemID = tostring(itemID)

  return self:GetListSV(listName)[itemID]
end

-- Sorts the specified item list.
-- @param list - a table of items to sort
function ListManager:SortList(list)
  -- Sort by name when same quality, otherwise sort by quality.
  sort(list, function(a, b)
    if ((a.Quality - b.Quality) == 0) then
      return (a.Name < b.Name) end

    return (a.Quality < b.Quality)
  end)
end

-- Removes all entries from the specified list.
-- @param listName - the name of the list to destroy
function ListManager:DestroyList(listName)
  assert(self[listName] ~= nil)

  -- Initialize data
  local listData = self:GetListData(listName)
  local list = listData.List
  local sv = listData.SV
  local coloredName = listData.ColoredName

  if not (#list > 0) then return end
  for k in pairs(list) do list[k] = nil end
  for k in pairs(sv) do sv[k] = nil end

  Core:Print(format(L.REMOVED_ALL_FROM_LIST, coloredName))
end

-- ============================================================================
--                            Transport Functions
-- ============================================================================

-- Parses an import string for item IDs to add to the specified list.
-- @param listName - the name of the list to import into
-- @param string - the import string with format: "itemID;itemID;itemID;"
function ListManager:ImportToList(listName, string)
  assert(self[listName] ~= nil)

  for itemID in string:gmatch('([^;]+)') do
    itemID = tonumber(itemID)
    if (itemID and (itemID > 0)) then
      self:AddToList(listName, itemID)
    end
  end
end

-- Creates and returns a string containing all item IDs on the specified list.
-- @param listName - the name of the list to export
-- @return - a string with format: "itemID;itemID;itemID;"
function ListManager:ExportFromList(listName)
  assert(self[listName] ~= nil)

  -- Initialize data
  local sv = self:GetListSV(listName)
  local itemIDs = {}

  for k in pairs(sv) do
    itemIDs[#itemIDs+1] = k
  end

  return concat(itemIDs, ";")
end

-- ============================================================================
--                              Parsing Functions
-- ============================================================================

local MAX_PARSE_ATTEMPTS = 100

-- Set OnUpdate script
function parseFrame:OnUpdate(elapsed)
  if DJ.Dejunker:IsDejunking() then return end

  -- Removals
  for listName, list in pairs(ListManager.ToRemove) do
    if next(list) then ListManager:CleanList(listName) end
  end

  -- Additions
  for listName, list in pairs(ListManager.ToAdd) do
    if next(list) then ListManager:ParseList(listName) end
  end
end

parseFrame:SetScript("OnUpdate", parseFrame.OnUpdate)

-- Cleans the specified list by removing queued entries.
-- @param listName - the name of the list to clean
function ListManager:CleanList(listName)
  assert(self[listName])

  -- Initialize data
  local listData = self:GetListData(listName)
  local toRemove = listData.ToRemove
  local coloredName = listData.ColoredName
  local sv = listData.SV
  local list = listData.List

  -- This function will cause the game to stall for a bit when removing thousands of items.
  -- So, my simple way of preventing that is to only run it a certain number of times each update.
  local rem = function(itemID)
    for k, v in pairs(list) do
      if (v.ItemID == itemID) then
        remove(list, k) -- remove has to be used here for the table to update as expected
        sv[itemID] = nil
        Core:Print(format(L.REMOVED_ITEM_FROM_LIST, v.ItemLink, coloredName))
        return
      end
    end
  end

  for i=1, 500 do
    local itemID = next(toRemove)
    if not itemID then return end
    rem(itemID)
    toRemove[itemID] = nil
  end
end

-- Parses queued itemIDs and adds them to the specified list.
-- @param listName - the name of the list to parse
function ListManager:ParseList(listName)
  assert(self[listName])

  -- Initialize data
  local listData = self:GetListData(listName)
  local toAdd = listData.ToAdd
  local coloredName = listData.ColoredName
  local sv = listData.SV
  local list = listData.List

  -- Returns true if the item can be sold, and the target list is Inclusions or Exclusions.
  local canBeSold = function(item)
    if not (listName == self.Inclusions or listName == self.Exclusions) then
      return false end

    if Tools:ItemCanBeSold(item) then
      return true end

    sv[item.ItemID] = nil
    toAdd[item.ItemID] = nil
    Core:Print(format(L.ITEM_CANNOT_BE_SOLD, item.ItemLink))
    return false
  end

  -- Returns true if the item can be destroyed, and the target list is Destroyables.
  local canBeDestroyed = function(item)
    if not (listName == self.Destroyables) then
      return false end

    if Tools:ItemCanBeDestroyed(item) then
      return true end

    sv[item.ItemID] = nil
    toAdd[item.ItemID] = nil
    Core:Print(format(L.ITEM_CANNOT_BE_DESTROYED, item.ItemLink))
    return false
  end

  -- Parse items
  for itemID in pairs(toAdd) do
    local item = Tools:GetItemByID(itemID)

    -- If item is not nil, test if the item can be destroyed or sold
    if item and (canBeSold(item) or canBeDestroyed(item)) then
      -- Print added msg if the item is NOT being parsed from sv (see ListManager:Update())
      if not sv[itemID] then
        sv[itemID] = true
        Core:Print(format(L.ADDED_ITEM_TO_LIST, item.ItemLink, coloredName))
      end

      list[#list+1] = item
      toAdd[itemID] = nil
    elseif not sv[itemID] then -- if the item couldn't be parsed, and it is not in the saved variables (avoids erasing sv data by accident)
      local attempts = ((parseFrame.AttemptsToParse[itemID] or 0) + 1)

      if (attempts >= MAX_PARSE_ATTEMPTS) then
        attempts = 0
        toAdd[itemID] = nil
        Core:Print(format(L.FAILED_TO_PARSE_ITEM_ID, DCL:ColorString(itemID, DCL.CSS.Grey)))
      end

      parseFrame.AttemptsToParse[itemID] = attempts
    end
  end

  -- Sort the list once all items have been parsed
  if not next(toAdd) then ListManager:SortList(list) end
end
