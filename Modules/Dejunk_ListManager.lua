-- Dejunk_ListManager: manages the Inclusions, Exclusions, and Destroyables lists in the saved variables.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local assert, pairs, next = assert, pairs, next
local insert, remove = table.insert, table.remove
local sort, concat = table.sort, table.concat
local tonumber, tostring = tonumber, tostring

-- Dejunk
local ListManager = DJ.ListManager

local Core = DJ.Core
local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB

-- Variables
ListManager.Initialized = false

ListManager.InclusionsList = {}
ListManager.ExclusionsList = {}
ListManager.DestroyablesList = {}

ListManager.Lists =
{
  ["Inclusions"] = ListManager.InclusionsList,
  ["Exclusions"] = ListManager.ExclusionsList,
  ["Destroyables"] = ListManager.DestroyablesList
}

ListManager.ToAdd = {}
ListManager.ToRemove = {}

-- Add list keys to ListManager, ToAdd, and ToRemove
for k in pairs(ListManager.Lists) do
  ListManager[k] = k
  ListManager.ToAdd[k] = {}
  ListManager.ToRemove[k] = {}
end

-- Saved Variables
local inclusionsSV = nil
local exclusionsSV = nil
local destroyablesSV = nil

-- Parsing Frame
local parseFrame = CreateFrame("Frame", AddonName.."ListManagerParseFrame")
parseFrame.AttemptsToParse = {} -- Format: ["itemID"] = numOfAttemptsToParse

--[[
//*******************************************************************
//                      List Manager Functions
//*******************************************************************
--]]

-- Initializes the ListManager.
function ListManager:Initialize()
  if self.Initialized then return end

  self:Update()

  self.Initialized = true
end

-- Updates the ListManager's references to lists in the saved variables.
function ListManager:Update()
  -- Clear inclusions, exclusions, and destroyables item data lists
  for k in pairs(self.InclusionsList) do self.InclusionsList[k] = nil end
  for k in pairs(self.ExclusionsList) do self.ExclusionsList[k] = nil end
  for k in pairs(self.DestroyablesList) do self.DestroyablesList[k] = nil end

  -- Reset SV references
  inclusionsSV = DejunkDB.SV.Inclusions
  exclusionsSV = DejunkDB.SV.Exclusions
  destroyablesSV = DejunkDB.SV.Destroyables

  -- Load lists' items
  for k, v in pairs(self.ToAdd) do
    for itemID in pairs(self:GetListSV(k)) do
      v[itemID] = true
    end
  end
end

-- Checks whether the ListManager is currently parsing either a specific list or in general.
-- @param listName - the name of the list to check for being parsed [optional]
-- @return - boolean
function ListManager:IsParsing(listName)
  local parsingInclusions = (next(self.ToAdd.Inclusions) or next(self.ToRemove.Inclusions))
  local parsingExclusions = (next(self.ToAdd.Exclusions) or next(self.ToRemove.Exclusions))
  local parsingDestroyables = (next(self.ToAdd.Destroyables) or next(self.ToRemove.Destroyables))

  if (listName == self.Inclusions) then
    return parsingInclusions
  elseif (listName == self.Exclusions) then
    return parsingExclusions
  elseif (listName == self.Destroyables) then
    return parsingDestroyables
  else -- parsing in general?
    -- This function is mainly used to test if the Inc or Exc list is being parsed,
    -- so that's why we don't check for parsingDestroyables here
    return (parsingInclusions or parsingExclusions)
  end
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
  local sV = self:GetListSV(listName)
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

--[[
//*******************************************************************
//                          List Functions
//*******************************************************************
--]]

-- Adds an item to the specified list.
-- @param listName - the name of the list to add to
-- @param itemID - the item id of the item to add
function ListManager:AddToList(listName, itemID)
  assert(self[listName] ~= nil)
  itemID = tostring(itemID)

  -- Initialize data
  local toAdd, coloredListName, otherListName, sv

  if (listName == self.Inclusions) then
    toAdd = self.ToAdd.Inclusions
    coloredListName = Tools:GetInclusionsString()
    otherListName = self.Exclusions
    sv = inclusionsSV
  elseif (listName == self.Exclusions) then
    toAdd = self.ToAdd.Exclusions
    coloredListName = Tools:GetExclusionsString()
    otherListName = self.Inclusions
    sv = exclusionsSV
  else -- Destroyables
    toAdd = self.ToAdd.Destroyables
    coloredListName = Tools:GetDestroyablesString()
    sv = destroyablesSV
  end

  -- Don't add if the item is already being parsed
  if toAdd[itemID] then return end

  -- Don't add if the item is already on the list
  local existingItem = self:GetItemFromList(listName, itemID)
  if existingItem then
    Core:Print(format(L.ITEM_ALREADY_ON_LIST, existingItem.Link, coloredListName))
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
function ListManager:RemoveFromList(listName, itemID)
  assert(self[listName] ~= nil)
  itemID = tostring(itemID)

  if not self:IsOnList(listName, itemID) then return end

  local toRemove

  if (listName == self.Inclusions) then
    toRemove = self.ToRemove.Inclusions
  elseif (listName == self.Exclusions) then
    toRemove = self.ToRemove.Exclusions
  else -- Destroyables
    toRemove = self.ToRemove.Destroyables
  end

  toRemove[itemID] = true
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

-- Searches for and returns an item in the specified list.
-- @param listName - the name of the list to search
-- @param itemID - the item id of the item to search for
-- @return - an item if it exists in the list, or nil
function ListManager:GetItemFromList(listName, itemID)
  assert(self[listName] ~= nil)
  itemID = tostring(itemID)

  if not self:IsOnList(listName, itemID) then return nil end

  -- Initialize data
  local list = self.Lists[listName]

  for i=1, #list do
    if (list[i].ItemID == itemID) then
      return list[i] end
  end

  return nil
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
  local list, sv, coloredListName

  if (listName == self.Inclusions) then
    list = self.InclusionsList
    sv = inclusionsSV
    coloredListName = Tools:GetInclusionsString()
  elseif (listName == self.Exclusions) then
    list = self.ExclusionsList
    sv = exclusionsSV
    coloredListName = Tools:GetExclusionsString()
  else -- Destroyables
    list = self.DestroyablesList
    sv = destroyablesSV
    coloredListName = Tools:GetDestroyablesString()
  end

  if not (#list > 0) then return end
  for k in pairs(list) do list[k] = nil end
  for k in pairs(sv) do sv[k] = nil end

  Core:Print(format(L.REMOVED_ALL_FROM_LIST, coloredListName))
end

--[[
//*******************************************************************
//                        Transport Functions
//*******************************************************************
--]]

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
  local sv

  if (listName == self.Inclusions) then
    sv = inclusionsSV
  elseif (listName == self.Exclusions) then
    sv = exclusionsSV
  else -- Destroyables
    sv = destroyablesSV
  end

  local itemIDs = {}

  for k in pairs(sv) do
    itemIDs[#itemIDs+1] = k
  end

  return concat(itemIDs, ";")
end

--[[
//*******************************************************************
//                          Parsing Functions
//*******************************************************************
--]]

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
  local toRemove, coloredListName, sv, list

  if (listName == self.Inclusions) then
    toRemove = self.ToRemove.Inclusions
    coloredListName = Tools:GetInclusionsString()
    sv = inclusionsSV
    list = self.InclusionsList
  elseif (listName == self.Exclusions) then
    toRemove = self.ToRemove.Exclusions
    coloredListName = Tools:GetExclusionsString()
    sv = exclusionsSV
    list = self.ExclusionsList
  else -- Destroyables
    toRemove = self.ToRemove.Destroyables
    coloredListName = Tools:GetDestroyablesString()
    sv = destroyablesSV
    list = self.DestroyablesList
  end

  -- This function will cause the game to stall for a bit when removing thousands of items.
  -- So, my simple way of preventing that is to only run it a certain number of times each update.
  local rem = function(itemID)
    for k, v in pairs(list) do
      if (v.ItemID == itemID) then
        remove(list, k)
        sv[itemID] = nil
        Core:Print(format(L.REMOVED_ITEM_FROM_LIST, v.Link, coloredListName))
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
  local toAdd, coloredListName, sv, list

  if (listName == self.Inclusions) then
    toAdd = self.ToAdd.Inclusions
    coloredListName = Tools:GetInclusionsString()
    sv = inclusionsSV
    list = self.InclusionsList
  elseif (listName == self.Exclusions) then
    toAdd = self.ToAdd.Exclusions
    coloredListName = Tools:GetExclusionsString()
    sv = exclusionsSV
    list = self.ExclusionsList
  else -- Destroyables
    toAdd = self.ToAdd.Destroyables
    coloredListName = Tools:GetDestroyablesString()
    sv = destroyablesSV
    list = self.DestroyablesList
  end

  local canBeSold = function(item)
    if Tools:ItemCanBeSold(item.Price, item.Quality) then
      return true end

    sv[item.ItemID] = nil
    toAdd[item.ItemID] = nil
    Core:Print(format(L.ITEM_CANNOT_BE_SOLD, item.Link))
    return false
  end

  -- Parse items
  for itemID in pairs(toAdd) do
    local item = Tools:GetItemByID(itemID)

    -- If item is not nil, test if list is Destroyables before calling canBeSold
    -- local destroy = (listName == self.Destroyables) and canBeDestroyed(item)
    -- if item and (destroy or canBeSold(item)) then
    if item and ((listName == self.Destroyables) or canBeSold(item)) then
      -- Print added msg if the item is NOT being parsed from sv (see ListManager:Update())
      if not sv[itemID] then
        sv[itemID] = true
        Core:Print(format(L.ADDED_ITEM_TO_LIST, item.Link, coloredListName))
      end

      --list[#list+1] = item
      insert(list, 1, item) -- more obvious visual in ListFrame when adding to the top
      toAdd[itemID] = nil
    elseif not sv[itemID] then -- if the item couldn't be parsed, and it is not in the saved variables (avoids erasing sv data by accident)
      local attempts = ((parseFrame.AttemptsToParse[itemID] or 0) + 1)

      if (attempts >= MAX_PARSE_ATTEMPTS) then
        attempts = 0
        toAdd[itemID] = nil
        Core:Print(format(L.FAILED_TO_PARSE_ITEM_ID, Tools:GetColorString(itemID, Colors.Grey)))
      end

      parseFrame.AttemptsToParse[itemID] = attempts
    end
  end

  -- Sort the list once all items have been parsed
  if not next(toAdd) then ListManager:SortList(list) end
end
