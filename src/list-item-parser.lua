local _, Addon = ...
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local ListItemParser = Addon:GetModule("ListItemParser")
local Seller = Addon:GetModule("Seller")
local TickerManager = Addon:GetModule("TickerManager")

local PARSE_DELAY_SECONDS = 0.1

--- @class ParsingOptions
--- @field parsedEvent string
--- @field failedToParseEvent string
--- @field maxParseAttempts number

--- @type table<string, ParsingOptions>
local PARSING_OPTIONS = {
  NEW_LIST_ITEM = {
    parsedEvent = E.ListItemParsed,
    failedToParseEvent = E.ListItemFailedToParse,
    maxParseAttempts = math.ceil(5 / PARSE_DELAY_SECONDS) -- Fail after 5 seconds.
  },
  EXISTING_LIST_ITEM = {
    parsedEvent = E.ExistingListItemParsed,
    failedToParseEvent = E.ExistingListItemFailedToParse,
    maxParseAttempts = math.ceil(30 / PARSE_DELAY_SECONDS) -- Fail after 30 seconds.
  }
}

--- Queue of item IDs to be parsed for lists where the item IDs are
--- not yet saved in SavedVariables.
--- @type table<table, table<string, boolean|nil>>
local newListItemQueue = {}

--- Queue of item IDs to be parsed for lists where the item IDs are
--- already saved in SavedVariables.
--- @type table<table, table<string, boolean|nil>>
local existingListItemQueue = {}

--- Parse attempts by list for each queued item ID.
--- @type table<table, table<string, number|nil>>
local listParseAttempts = {}

--- Cache for items that have been successfully parsed.
--- @type table<string, table>
local itemCache = {}

-- ============================================================================
-- Functions
-- ============================================================================

--- Initiates parsing for the given list and item ID,
--- specifically for item IDs that are not yet part of saved variables.
--- @param list table
--- @param itemId string|number
function ListItemParser:Parse(list, itemId)
  if not newListItemQueue[list] then newListItemQueue[list] = {} end
  newListItemQueue[list][tostring(itemId)] = true
end

--- Initiates parsing for the given list and item ID,
--- specifically for item IDs that are already part of saved variables.
--- @param list table
--- @param itemId string|number
function ListItemParser:ParseExisting(list, itemId)
  if not existingListItemQueue[list] then existingListItemQueue[list] = {} end
  existingListItemQueue[list][tostring(itemId)] = true
end

--- Returns `true` if any item IDs are currently queued for parsing.
--- @return boolean
function ListItemParser:IsBusy()
  for _, itemIds in pairs(newListItemQueue) do
    if next(itemIds) then return true end
  end

  for _, itemIds in pairs(existingListItemQueue) do
    if next(itemIds) then return true end
  end

  return false
end

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Attempts to retrieve item data for the given item ID.
--- @param itemId string
--- @return table|nil
local function getItemById(itemId)
  if not itemCache[itemId] then
    local name, link, quality, _, _, _, _, _, _, texture, price, classId = GetItemInfo(itemId)
    if type(link) == "string" then
      itemCache[itemId] = {
        id = itemId,
        name = name,
        link = link,
        quality = quality,
        texture = texture,
        price = price,
        classId = classId
      }
    end
  end

  return itemCache[itemId]
end

--- Increments and returns the number of parse attempts for the given list and item ID.
--- @param list table
--- @param itemId string
--- @return number parseAttempts
local function incrementParseAttempts(list, itemId)
  if not listParseAttempts[list] then listParseAttempts[list] = {} end
  local parseAttempts = (listParseAttempts[list][itemId] or 0) + 1
  listParseAttempts[list][itemId] = parseAttempts
  return parseAttempts
end

--- Resets the number of parse attempts for the given list and item ID.
--- @param list table
--- @param itemId string
local function resetParseAttempts(list, itemId)
  if not listParseAttempts[list] then listParseAttempts[list] = {} end
  listParseAttempts[list][itemId] = nil
end

--- Return `true` if there are no more item IDs for the given list to be parsed.
--- @param list table
--- @return boolean
local function isListParsingComplete(list)
  if newListItemQueue[list] and next(newListItemQueue[list]) then
    return false
  end

  if existingListItemQueue[list] and next(existingListItemQueue[list]) then
    return false
  end

  return true
end

--- Attempts to parse items for a list.
--- @param list table
--- @param itemIds table<string, boolean|nil>
--- @param options ParsingOptions
local function parse(list, itemIds, options)
  if not next(itemIds) then return end

  -- Attempt to parse items.
  for itemId in pairs(itemIds) do
    if not GetItemInfoInstant(itemId) then
      itemIds[itemId] = nil
      EventManager:Fire(E.ListItemCannotBeParsed, list, itemId)
    else
      local item = getItemById(itemId)
      if item then
        itemIds[itemId] = nil
        EventManager:Fire(options.parsedEvent, list, item)
      else
        local parseAttempts = incrementParseAttempts(list, itemId)
        if parseAttempts >= options.maxParseAttempts then
          resetParseAttempts(list, itemId)
          itemIds[itemId] = nil
          EventManager:Fire(options.failedToParseEvent, list, itemId)
        end
      end
    end
  end

  if isListParsingComplete(list) then
    EventManager:Fire(E.ListParsingComplete, list)
  end
end

-- ============================================================================
-- Ticker to parse the list item queues.
-- ============================================================================

TickerManager:NewTicker(PARSE_DELAY_SECONDS, function()
  if Seller:IsBusy() then return end

  for list, itemIds in pairs(newListItemQueue) do
    parse(list, itemIds, PARSING_OPTIONS.NEW_LIST_ITEM)
  end

  for list, itemIds in pairs(existingListItemQueue) do
    parse(list, itemIds, PARSING_OPTIONS.EXISTING_LIST_ITEM)
  end
end)
