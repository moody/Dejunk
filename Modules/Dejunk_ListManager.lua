--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_ListManager: manages the Inclusions and Exclusions lists in the saved variables.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local pairs, next, tonumber = pairs, next, tonumber
local insert, remove = table.insert, table.remove
local sort, concat = table.sort, table.concat

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

ListManager.Lists =
{
  ["Inclusions"] = ListManager.InclusionsList,
  ["Exclusions"] = ListManager.ExclusionsList,
}

-- Add list keys
for k in pairs(ListManager.Lists) do ListManager[k] = k end

-- Saved Variables
local inclusionsSV = nil
local exclusionsSV = nil

-- Parsing Frame
local parseFrame = CreateFrame("Frame", AddonName.."ListManagerParseFrame")
parseFrame.InclusionsToAdd = {}
parseFrame.InclusionsToRemove = {}
parseFrame.ExclusionsToAdd = {}
parseFrame.ExclusionsToRemove = {}
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
  -- Clear inclusions and exclusions item data lists
  for k in pairs(self.InclusionsList) do self.InclusionsList[k] = nil end
  for k in pairs(self.ExclusionsList) do self.ExclusionsList[k] = nil end

  -- Reset SV references
  inclusionsSV = DejunkDB.SV.Inclusions
  exclusionsSV = DejunkDB.SV.Exclusions

  local inCount = 0 -- debug
  local exCount = 0 -- debug

  -- Load inclusions and exclusions items
  for itemID in pairs(inclusionsSV) do
    parseFrame.InclusionsToAdd[itemID] = true
    inCount = inCount + 1
  end

  for itemID in pairs(exclusionsSV) do
    parseFrame.ExclusionsToAdd[itemID] = true
    exCount = exCount + 1
  end
end

-- Checks whether the ListManager is currently parsing either a specific list or in general.
-- @param listName - the name of the list to check for being parsed [optional]
-- @return - boolean
function ListManager:IsParsing(listName)
  local parsingInclusions = (next(parseFrame.InclusionsToRemove) or next(parseFrame.InclusionsToAdd))
  local parsingExclusions = (next(parseFrame.ExclusionsToRemove) or next(parseFrame.ExclusionsToAdd))

  if (listName == self.Inclusions) then
    return parsingInclusions
  elseif (listName == self.Exclusions) then
    return parsingExclusions
  else -- parsing in general?
    return (parsingInclusions or parsingExclusions)
  end
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
  local toAdd, coloredListName, otherListName, sv, otherSV

  if (listName == self.Inclusions) then
    toAdd = parseFrame.InclusionsToAdd
    coloredListName = Tools:GetInclusionsString()
    otherListName = self.Exclusions
    sv = inclusionsSV
    otherSV = exclusionsSV
  else -- Exclusions
    toAdd = parseFrame.ExclusionsToAdd
    coloredListName = Tools:GetExclusionsString()
    otherListName = self.Inclusions
    sv = exclusionsSV
    otherSV = inclusionsSV
  end

  -- Don't add if the item is already being parsed
  local beingParsed = toAdd[itemID]
  if beingParsed then return end

  -- Don't add if the item is already on the list
  if self:IsOnList(listName, itemID) then
    -- TODO: Maybe try and improve this? It runs slow when mass importing duplicate items, but this shouldn't be an issue for the average user.
    -- Could try to parse the link and if it doesn't return then don't print anything.
    local item = self:GetItemFromList(listName, itemID)
    Core:Print(format(L.ITEM_ALREADY_ON_LIST, item.Link, coloredListName))
    return
  end

  -- If the item is on the other list, remove it first
  if otherSV[itemID] then
    self:RemoveFromList(otherListName, itemID)
  end

  -- Finally, add the item for parsing
  toAdd[itemID] = true
end

-- Removes an item from the specified list.
-- @param listName - the name of the list to remove from
-- @param itemID - the item id of the item to remove
function ListManager:RemoveFromList(listName, itemID)
  assert(self[listName] ~= nil)

  itemID = tostring(itemID)

  -- Initialize data
  local toRemove, sv

  if (listName == self.Inclusions) then
    toRemove = parseFrame.InclusionsToRemove
    sv = inclusionsSV
  else -- Exclusions
    toRemove = parseFrame.ExclusionsToRemove
    sv = exclusionsSV
  end

  -- Don't remove item if it doesn't need to be
  if sv[itemID] then
    toRemove[itemID] = true end
end

-- Checks whether or not an item exists in the specified list.
-- @param listName - the name of the list to search
-- @param itemID - the item id of the item to search for
-- @return - boolean
function ListManager:IsOnList(listName, itemID)
  assert(self[listName] ~= nil)

  itemID = tostring(itemID)

  -- Initialize data
  local sv

  if (listName == self.Inclusions) then
    sv = inclusionsSV
  else -- Exclusions
    sv = exclusionsSV
  end

  return (sv[itemID] ~= nil)
end

-- Searches for and returns an item in the specified list.
-- @param listName - the name of the list to search
-- @param itemID - the item id of the item to search for
-- @return - an item if it exists in the list, or nil
function ListManager:GetItemFromList(listName, itemID)
  assert(self[listName] ~= nil)

  itemID = tostring(itemID)

  -- Initialize data
  local list

  if (listName == self.Inclusions) then
    list = self.InclusionsList
  else -- Exclusions
    list = self.ExclusionsList
  end

  -- Functionality
  for k, v in pairs(list) do
    if (v.ItemID == itemID) then
      return v end
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
  else -- Exclusions
    list = self.ExclusionsList
    sv = exclusionsSV
    coloredListName = Tools:GetExclusionsString()
  end

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
  else -- Exclusions
    sv = exclusionsSV
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
parseFrame:SetScript("OnUpdate", function(self, elapsed)
  if DJ.Dejunker:IsDejunking() then return end

  -- Removals
  if next(self.InclusionsToRemove) then
    ListManager:CleanList(ListManager.Inclusions) end
  if next(self.ExclusionsToRemove) then
    ListManager:CleanList(ListManager.Exclusions) end

  -- Additions
  if next(self.InclusionsToAdd) then
    ListManager:ParseList(ListManager.Inclusions) end
  if next(self.ExclusionsToAdd) then
    ListManager:ParseList(ListManager.Exclusions) end
end)

-- Cleans the specified list by removing queued entries.
-- @param listName - the name of the list to clean
function ListManager:CleanList(listName)
  assert(self[listName])

  -- Initialize data
  local toRemove, coloredListName, sv, list

  if (listName == self.Inclusions) then
    toRemove = parseFrame.InclusionsToRemove
    coloredListName = Tools:GetInclusionsString()
    sv = inclusionsSV
    list = self.InclusionsList
  else -- Exclusions
    toRemove = parseFrame.ExclusionsToRemove
    coloredListName = Tools:GetExclusionsString()
    sv = exclusionsSV
    list = self.ExclusionsList
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
    toAdd = parseFrame.InclusionsToAdd
    coloredListName = Tools:GetInclusionsString()
    sv = inclusionsSV
    list = self.InclusionsList
  else -- Exclusions
    toAdd = parseFrame.ExclusionsToAdd
    coloredListName = Tools:GetExclusionsString()
    sv = exclusionsSV
    list = self.ExclusionsList
  end

  for itemID in pairs(toAdd) do
    local item = Tools:GetItemByID(itemID)

    if item then
      if not Tools:ItemCanBeSold(item.Price, item.Quality) then
        sv[itemID] = nil
        toAdd[itemID] = nil
        Core:Print(format(L.ITEM_CANNOT_BE_SOLD, item.Link))
        return
      end

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

    -- Sort the list once all items have been parsed
    if not next(toAdd) then ListManager:SortList(list) end
  end
end
