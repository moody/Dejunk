local _, Addon = ...
local Core = Addon.Core
local DB = Addon.DB
local DBL = Addon.Libs.DBL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local ERROR_CAPS = _G.ERROR_CAPS
local Filters = Addon.Filters
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local Tools = Addon.Tools

-- Filter arrays
Filters[Dejunker] = {}
Filters[Destroyer] = {}

-- DBL filter functions
Filters.DBL = {
  [Dejunker] = function(item)
    if -- Ignore item if it is locked, refundable, or not sellable
      item:IsLocked() or
      Tools:ItemCanBeRefunded(item) or
      not Tools:ItemCanBeSold(item)
    then
      return false
    end

    local isJunk = Filters:Run(Dejunker, item)
    return isJunk
  end,
  [Destroyer] = function(item)
    if -- Ignore item if it is locked, refundable, or not destroyable
      item:IsLocked() or
      Tools:ItemCanBeRefunded(item) or
      not Tools:ItemCanBeDestroyed(item)
    then
      return false
    end

    local isJunk = Filters:Run(Destroyer, item)
    return isJunk
  end
}

-- Adds a filter for the specified table.
-- @param {table} t - Dejunker, Destroyer
-- @param {table} filter
function Filters:Add(t, filter)
  --[[ Filter spec:
  -- Called before retrieving filtered items via DBL.
  function Filter:Before()
    ...
  end

  -- Called while filtering items via DBL.
  -- @param {table} item - the DBL item to be tested
  -- @return {string} result - "JUNK", "NOT_JUNK", or "PASS"
  -- @return {string | nil} reason - string indicating why the item is
  -- considered to be junk or not, and nil if `result` is "PASS"
  function Filter:Run(item)
    return result, reason
  end

  -- Called after retrieving filtered items via DBL.
  -- @param {table} items - array of DBL items which were determined to be junk
  function Filter:After(items)
    ...
  end
  --]]

  assert(self[t])
  assert(type(filter) == "table")
  assert(type(filter.Run) == "function")
  if filter.Before then assert(type(filter.Before) == "function") end
  if filter.After then assert(type(filter.After) == "function") end

  local filters = self[t]

  -- Don't add same filter more than once
  for i in pairs(filters) do
    if filters[i] == filter then return end
  end

  filters[#filters+1] = filter
end

-- Runs all filters for the specified table and stores the results in `items`.
-- @param {table} t - Dejunker, Destroyer
-- @param {table} items - array to fill with DBL items
-- @param {number} maxItems [optional]
function Filters:GetItems(t, items, maxItems)
  assert(self[t])
  assert(type(items) == "table")
  self._incompleteTooltips = false

  -- Before
  for _, filter in ipairs(self[t]) do
    if filter.Before then filter:Before() end
  end

  -- Filter items via DBL
  DBL:GetItemsByFilter(self.DBL[t], items, maxItems)

  -- Print message if `IncompleteTooltipError()` was called
  if self._incompleteTooltips then
    Core:Print(L.IGNORING_ITEMS_INCOMPLETE_TOOLTIPS)
  end

  -- After
  for _, filter in ipairs(self[t]) do
    if filter.After then filter:After(items) end
  end
end

-- Provides return values for filters which rely on tooltip scanning if scanning
-- cannot be performed.
function Filters:IncompleteTooltipError()
  self._incompleteTooltips = true
  return "NOT_JUNK", ERROR_CAPS
end

-- ============================================================================
-- Filters:Run()
-- ============================================================================

-- Runs the item through the specified table's filters, and returns a boolean
-- and string indicating if and why the item will be sold or destroyed.
-- @param {table} t - Dejunker, Destroyer
-- @param {table} item - a DBL item
function Filters:Run(t, item)
  assert(self[t])

  -- Locked
  if item:IsLocked() then
    return false, L.REASON_ITEM_IS_LOCKED_TEXT
  end

  -- Filters
  for _, filter in ipairs(self[t]) do
    local result, reason = filter:Run(item)

    if result and result ~= "PASS" then
      -- Special handling for Sell/Destroy Below Price options
      if
        result == "JUNK" and
        Tools:ItemCanBeSold(item) and
        (
          (t == Dejunker and DB.Profile.SellBelowPrice.Enabled) or
          (t == Destroyer and DB.Profile.DestroyBelowPrice.Enabled)
        )
      then
        local maxPrice =
          t == Dejunker and
          DB.Profile.SellBelowPrice.Value or
          DB.Profile.DestroyBelowPrice.Value

        if (item.Price * item.Quantity) >= maxPrice then
          result = "NOT_JUNK"
          reason = L.REASON_ITEM_PRICE_IS_NOT_BELOW_TEXT:format(
            GetCoinTextureString(maxPrice)
          )
        end
      end

      return result == "JUNK", reason
    end
  end

  -- Not filtered
  return false, L.REASON_ITEM_NOT_FILTERED_TEXT
end
