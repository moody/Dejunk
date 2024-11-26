local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant or GetItemInfoInstant
local TickerManager = Addon:GetModule("TickerManager")

--- @class ListItemParser
local ListItemParser = Addon:GetModule("ListItemParser")

local PARSE_DELAY_SECONDS = 0.1
local PARSE_ATTEMPTS_PER_CALL = 25

--- @class ParsingOptions
--- @field silent boolean
--- @field maxParseAttempts number

--- @type table<string, ParsingOptions>
local PARSING_OPTIONS = {
  NEW_LIST_ITEM = {
    silent = false,
    maxParseAttempts = math.ceil(5 / PARSE_DELAY_SECONDS) -- Fail after 5 seconds.
  },
  EXISTING_LIST_ITEM = {
    silent = true,
    maxParseAttempts = math.ceil(30 / PARSE_DELAY_SECONDS) -- Fail after 30 seconds.
  }
}

--- Queue of item IDs to be parsed for lists where the item IDs are
--- not yet saved in SavedVariables.
--- @type table<List, ListItemIds>
local newListItemQueue = {}

--- Queue of item IDs to be parsed for lists where the item IDs are
--- already saved in SavedVariables.
--- @type table<List, ListItemIds>
local existingListItemQueue = {}

--- Parse attempts by list for each queued item ID.
--- @type table<List, table<string, number>>
local listParseAttempts = {}

--- Cache for items that have been successfully parsed.
--- @type table<string, ListItem>
local itemCache = {}

-- ============================================================================
-- Functions
-- ============================================================================

--- Returns a parsed item from the cache, if it exists.
--- @param itemId string|number
--- @return ListItem?
function ListItemParser:GetParsedItem(itemId)
  return itemCache[tostring(itemId)]
end

--- Initiates parsing for the given `list` and `itemId`,
--- specifically for item IDs that are not yet part of saved variables.
--- @param list List
--- @param itemId string|number
function ListItemParser:Parse(list, itemId)
  if not newListItemQueue[list] then newListItemQueue[list] = {} end
  newListItemQueue[list][tostring(itemId)] = true
end

--- Initiates parsing for the given `list` and `itemId`,
--- specifically for item IDs that are already part of saved variables.
--- @param list List
--- @param itemId string|number
function ListItemParser:ParseExisting(list, itemId)
  if not existingListItemQueue[list] then existingListItemQueue[list] = {} end
  existingListItemQueue[list][tostring(itemId)] = true
end

--- Cancels parsing for the given `list` and `itemId`.
--- @param list List
--- @param itemId string|number
function ListItemParser:CancelParse(list, itemId)
  itemId = tostring(itemId)
  if newListItemQueue[list] then newListItemQueue[list][itemId] = nil end
  if existingListItemQueue[list] then existingListItemQueue[list][itemId] = nil end
  if listParseAttempts[list] then listParseAttempts[list][itemId] = nil end
end

--- Stops all parsing for the given `list`.
--- @param list List
function ListItemParser:StopParsing(list)
  newListItemQueue[list] = {}
  existingListItemQueue[list] = {}
  listParseAttempts[list] = {}
end

--- Returns `true` if any items are currently being parsed for the given `list`.
--- @param list List
--- @return boolean
function ListItemParser:IsParsing(list)
  if newListItemQueue[list] and next(newListItemQueue[list]) then return true end
  if existingListItemQueue[list] and next(existingListItemQueue[list]) then return true end
  return false
end

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Attempts to retrieve item data for the given `itemId`.
--- @param itemId string
--- @return ListItem? item
local function getItemById(itemId)
  if not itemCache[itemId] then
    local name, link, quality, _, _, _, _, _, _, texture, price, classId = GetItemInfo(itemId)
    if type(link) == "string" then
      --- @class ListItem
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

--- Increments and returns the number of parse attempts for the given `list` and `itemId`.
--- @param list List
--- @param itemId string
--- @return number parseAttempts
local function incrementParseAttempts(list, itemId)
  if not listParseAttempts[list] then listParseAttempts[list] = {} end
  local parseAttempts = (listParseAttempts[list][itemId] or 0) + 1
  listParseAttempts[list][itemId] = parseAttempts
  return parseAttempts
end

--- Resets the number of parse attempts for the given `list` and `itemId`.
--- @param list List
--- @param itemId string
local function resetParseAttempts(list, itemId)
  if not listParseAttempts[list] then listParseAttempts[list] = {} end
  listParseAttempts[list][itemId] = nil
end

--- Attempts to parse items for a list.
--- @param list List
--- @param itemIds ListItemIds
--- @param options ParsingOptions
local function parse(list, itemIds, options)
  if not next(itemIds) then return end

  -- Counter to limit iterations.
  local counter = 0

  -- Attempt to parse items.
  for itemId in pairs(itemIds) do
    if counter >= PARSE_ATTEMPTS_PER_CALL then break end
    counter = counter + 1

    if not GetItemInfoInstant(itemId) then
      itemIds[itemId] = nil
      EventManager:Fire(E.ListItemCannotBeParsed, list, itemId, options.silent)
    else
      local item = getItemById(itemId)
      if item then
        itemIds[itemId] = nil
        EventManager:Fire(E.ListItemParsed, list, item, options.silent)
      else
        local parseAttempts = incrementParseAttempts(list, itemId)
        if parseAttempts >= options.maxParseAttempts then
          resetParseAttempts(list, itemId)
          itemIds[itemId] = nil
          EventManager:Fire(E.ListItemFailedToParse, list, itemId, options.silent)
        end
      end
    end
  end
end

-- ============================================================================
-- Ticker to parse the list item queues.
-- ============================================================================

TickerManager:NewTicker(PARSE_DELAY_SECONDS, function()
  for list, itemIds in pairs(newListItemQueue) do
    parse(list, itemIds, PARSING_OPTIONS.NEW_LIST_ITEM)
  end

  for list, itemIds in pairs(existingListItemQueue) do
    parse(list, itemIds, PARSING_OPTIONS.EXISTING_LIST_ITEM)
  end
end)
