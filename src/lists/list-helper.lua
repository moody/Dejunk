local _, Addon = ...
local Chat = Addon.Chat
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local GetItemInfo = _G.GetItemInfo
local GetItemInfoInstant = _G.GetItemInfoInstant
local L = Addon.Libs.L
local ListHelper = Addon.ListHelper
local Lists = Addon.Lists
local tsort = table.sort

-- ============================================================================
-- Sorting
-- ============================================================================

do
  ListHelper._sortBy = "QUALITY"

  local sorts = {
    CLASS = {
      locale = L.CLASS_TEXT,
      func = function(a, b)
        return (
          a.Class == b.Class and
          a.Name < b.Name or
          a.Class < b.Class
        )
      end
    },

    NAME = {
      locale = L.NAME_TEXT,
      func = function(a, b)
        return a.Name < b.Name
      end
    },

    PRICE = {
      locale = L.PRICE_TEXT,
      func = function(a, b)
        return (
          a.Price == b.Price and
          a.Name < b.Name or
          a.Price < b.Price
        )
      end
    },

    QUALITY = {
      locale = L.QUALITY_TEXT,
      func = function(a, b)
        return (
          a.Quality == b.Quality and
          a.Name < b.Name or
          a.Quality < b.Quality
        )
      end
    }
  }

  -- Returns a list of key-value pairs for a "Sort By" dropdown menu.
  -- @return {table}
  function ListHelper:GetDropdownList()
    local list = {}
    for k, v in pairs(sorts) do list[k] = v.locale end
    return list
  end

  -- Returns the current "Sort By" dropdown value.
  -- @return {string}
  function ListHelper:GetDropdownValue()
    return self._sortBy
  end

  -- Sets the sorting method to use and immediately sorts every list.
  -- @param {string} by - a key in `sorts`
  function ListHelper:SortBy(by)
    self._sortBy = by
    for list in Lists.allLists() do
      tsort(list.items, sorts[by].func)
    end
  end

  -- Sorts the specified list.
  -- @param {table} list
  function ListHelper:Sort(list)
    tsort(list.items, sorts[self._sortBy].func)
  end
end

-- ============================================================================
-- Parsing
-- ============================================================================

-- Returns true if the `ListHelper` is currently parsing either a specific list
-- or in general.
-- @param {table} list - [optional]
-- @return {boolean}
function ListHelper:IsParsing(list)
  -- parsing specific list?
  if list then
    return next(list.toAdd) ~= nil
  end

  -- parsing in general?
  for li in Lists.allLists() do
    if next(li.toAdd) then return true end
  end

  return false
end

do -- OnUpdate(), called in Core:OnUpdate()
  local interval = 0

  function ListHelper:OnUpdate(elapsed)
    if Dejunker:IsDejunking() then return end

    -- Additions
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0
      for list in Lists.allLists() do
        self:ParseList(list)
      end
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

  -- Parses queued itemIDs and adds them to the specified list.
  -- @param {table} list - the list to parse
  function ListHelper:ParseList(list)
    if not next(list.toAdd) then return end

    -- Parse items
    for itemID in pairs(list.toAdd) do
      -- Instantly fail if item doesn't exist
      if not GetItemInfoInstant(itemID) then
        list._sv[itemID] = nil -- remove from sv
        list.toAdd[itemID] = nil -- remove from queue
        Chat:Print(
          L.FAILED_TO_PARSE_ITEM_ID:format(
            DCL:ColorString(itemID, DCL.CSS.Grey)
          )
        )
      else
        -- Attempt to parse the item
        local item = getItemByID(itemID)
        if item then
          -- Remove from sv if item cannot be added
          if not list:FinalizeAdd(item) then
            list._sv[itemID] = nil
          end
          -- Remove from parsing
          parseAttempts[itemID] = nil
          list.toAdd[itemID] = nil
        else
          -- Retry parsing until max attempts reached
          local attempts = (parseAttempts[itemID] or 0) + 1
          if (attempts >= MAX_PARSE_ATTEMPTS) then
            parseAttempts[itemID] = nil
            list._sv[itemID] = nil -- remove from sv
            list.toAdd[itemID] = nil -- remove from parsing
            Chat:Print(
              L.FAILED_TO_PARSE_ITEM_ID:format(
                DCL:ColorString(itemID, DCL.CSS.Grey)
              )
            )
          else
            parseAttempts[itemID] = attempts
          end
        end
      end
    end

    -- Sort the list once all items have been parsed
    if not next(list.toAdd) then self:Sort(list) end
  end
end
