local _, Addon = ...
local Bags = Addon.Bags
local Chat = Addon.Chat
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local ERROR_CAPS = _G.ERROR_CAPS
local Filters = Addon.Filters
local L = Addon.Libs.L
local Utils = Addon.Utils
local concat = table.concat

-- Filter arrays
Filters[Dejunker] = {}
Filters[Destroyer] = {}


-- Adds a filter for the specified table.
-- @param {table} filterType - Dejunker | Destroyer
-- @param {table} filter
function Filters:Add(filterType, filter)
  --[[ Filter spec:
  -- Called before filtering items.
  function Filter:Before()
    ...
  end

  -- Called while filtering items.
  -- @param {table} item - the item to be tested
  -- @return {string} result - "JUNK", "NOT_JUNK", or "PASS"
  -- @return {string | nil} reason - string indicating why the item is
  -- considered to be junk or not, and nil if `result` is "PASS"
  function Filter:Run(item)
    return result, reason
  end

  -- Called after filtering items.
  -- @param {table} items - array of items which were determined to be junk
  function Filter:After(items)
    ...
  end
  --]]

  assert(self[filterType])
  assert(type(filter) == "table")
  assert(type(filter.Run) == "function")
  if filter.Before then assert(type(filter.Before) == "function") end
  if filter.After then assert(type(filter.After) == "function") end

  local filters = self[filterType]

  -- Don't add same filter more than once
  for i in pairs(filters) do
    if filters[i] == filter then return end
  end

  filters[#filters+1] = filter
end


-- Runs the item through the specified table's filters, and returns a boolean
-- and string indicating if and why the item will be sold or destroyed. If a
-- reason string is not returned, the item was immediately ignored.
-- @param {table} filterType - Dejunker | Destroyer
-- @param {table} item
-- @return {boolean} isJunk
-- @return {string | nil} reason
function Filters:Run(filterType, item)
  assert(self[filterType])

  -- Ignore items that are refundable, unsellable, or undestroyable
  if
    Utils:ItemCanBeRefunded(item) or
    (filterType == Dejunker and not Utils:ItemCanBeSold(item)) or
    (filterType == Destroyer and not Utils:ItemCanBeDestroyed(item))
  then
    return false
  end

  -- Locked
  if Bags:IsLocked(item) then
    return false, L.REASON_ITEM_IS_LOCKED_TEXT
  end

  -- Filters
  for _, filter in ipairs(self[filterType]) do
    local result, reason = filter:Run(item)
    if result and result ~= "PASS" then
      return result == "JUNK", reason
    end
  end

  -- Not filtered
  return false, L.REASON_ITEM_NOT_FILTERED_TEXT
end


-- Returns a table of items in the player's bags which match the specified
-- filter type.
-- @param {table} filterType - Dejunker | Destroyer
-- @param {table} items
-- @return {table} items
function Filters:GetItems(filterType, items)
  assert(self[filterType])
  self._incompleteTooltips = false

  items = Bags:GetItems(items)
  if #items == 0 then return items end

  local filters = self[filterType]

  -- Before
  for _, filter in ipairs(filters) do
    if filter.Before then filter:Before() end
  end

  -- Filter items
  for i = #items, 1, -1 do
    local item = items[i]
    local isJunk, reason = self:Run(filterType, item)
    if isJunk and reason then
      item.Reason = reason
    else
      table.remove(items, i)
    end
  end

  -- Print message if `IncompleteTooltipError()` was called
  if self._incompleteTooltips then
    Chat:Print(L.IGNORING_ITEMS_INCOMPLETE_TOOLTIPS)
  end

  -- After
  for _, filter in ipairs(filters) do
    if filter.After then filter:After(items) end
  end

  return items
end


-- Provides return values for filters which rely on tooltip scanning if scanning
-- cannot be performed.
function Filters:IncompleteTooltipError()
  self._incompleteTooltips = true
  return "NOT_JUNK", ERROR_CAPS
end


-- Constructs a reason string via snippets.
function Filters:Reason(...)
  return concat({ ... }, " > ")
end

-- Constructs a sell reason string.
function Filters:SellReason(...)
  return self:Reason(L.SELL_TEXT, ...)
end

-- Constructs a destroy reason string.
function Filters:DestroyReason(...)
  return self:Reason(L.DESTROY_TEXT, ...)
end

-- Constructs a sell/destroy reason string pair.
function Filters:SharedReason(...)
  return self:SellReason(...), self:DestroyReason(...)
end
