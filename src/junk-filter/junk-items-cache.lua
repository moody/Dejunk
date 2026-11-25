local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local ItemFilters = Addon:GetModule("ItemFilters")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager")

--- @class JunkItemsCache
local JunkItemsCache = Addon:GetModule("JunkItemsCache")

--- Seconds that `GetNumJunkItems()` keeps its counts.
--- @type number
JunkItemsCache.COUNT_INTERVAL_SECONDS = 0.25

--- Format of the text from `GetNumJunkItemsText()`.
local COUNTS_TEXT_FORMAT = Colors.Grey("(%s/%s)"):format(Colors.White("%s"), Colors.Red("%s"))

--- The text from `GetNumJunkItemsText()` until the bag items have been scanned.
local NO_COUNTS_TEXT = COUNTS_TEXT_FORMAT:format("-", "-")

-- ============================================================================
-- State
-- ============================================================================

-- --------------------------------------
-- Junk items
-- --------------------------------------

--- The bag items that are checked for junk.
--- @type BagItem[]
local bagItems = {}

--- The bag items that are junk for selling or destroying, in sort order.
--- @type BagItem[]
local junkItems = {}

--- @class JunkResults
--- @field items BagItem[] The items in `junkItems` that are junk for the action, in sort order.
--- @field filterResults table<BagItem, ItemFilterResult> The filter result of each bag item for the action.
--- @field reasons table<BagItem, string> The reason each bag item is or is not junk for the action.

--- Junk results for selling.
--- @type JunkResults
local SellResults = { items = {}, filterResults = {}, reasons = {} }

--- Junk results for destroying.
--- @type JunkResults
local DestroyResults = { items = {}, filterResults = {}, reasons = {} }

--- The version that the junk items were found for.
--- @type integer?
local junkItemsVersion

-- --------------------------------------
-- Counts
-- --------------------------------------

--- The junk item counts, and the text built from them.
local Counts = {
  numSellable = 0,
  numDestroyable = 0,

  --- The version that the counts were found for.
  --- @type integer?
  version = nil,

  --- The time of the last count.
  time = 0,

  --- The text from `GetNumJunkItemsText()`.
  text = NO_COUNTS_TEXT,

  --- The sellable count that `text` shows.
  --- @type integer?
  textSellable = nil,

  --- The destroyable count that `text` shows.
  --- @type integer?
  textDestroyable = nil
}

-- --------------------------------------
-- Buffer
-- --------------------------------------

--- The reusable list that the count and next item methods fill.
--- @type BagItem[]
local itemsBuffer = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Empties the given table.
--- @param t table
local function clear(t)
  for key in pairs(t) do t[key] = nil end
end

--- Empties the tables of the given junk results.
--- @param results JunkResults
local function clearResults(results)
  clear(results.items)
  clear(results.filterResults)
  clear(results.reasons)
end

--- Finds the junk items again if the version changed since they were found.
local function updateJunkItems()
  local version = JunkItemsCache:GetVersion()
  if version == junkItemsVersion then return end
  junkItemsVersion = version

  clear(junkItems)
  clearResults(SellResults)
  clearResults(DestroyResults)

  for _, item in ipairs(BagItemsCache:GetItems(bagItems)) do
    local sellResult, sellReason = JunkFilter:GetResult(item, "SELL")
    local destroyResult, destroyReason = JunkFilter:GetResult(item, "DESTROY")
    SellResults.filterResults[item] = sellResult
    SellResults.reasons[item] = sellReason
    DestroyResults.filterResults[item] = destroyResult
    DestroyResults.reasons[item] = destroyReason

    if sellResult == ItemFilters.JUNK or destroyResult == ItemFilters.JUNK then
      junkItems[#junkItems + 1] = item
    end
  end

  table.sort(junkItems, Items.compareByStackPrice)

  for _, item in ipairs(junkItems) do
    if SellResults.filterResults[item] == ItemFilters.JUNK then
      SellResults.items[#SellResults.items + 1] = item
    end

    if DestroyResults.filterResults[item] == ItemFilters.JUNK then
      DestroyResults.items[#DestroyResults.items + 1] = item
    end
  end
end

--- Returns `true` if nothing stops the given junk `item` from being sold right now.
--- @param item BagItem
--- @return boolean
local function isSellable(item)
  return not Items:IsItemLocked(item) and JunkFilter:GetSellBlockReason(item) == nil
end

--- Returns `true` if nothing stops the given junk `item` from being destroyed right now.
--- @param item BagItem
--- @return boolean
local function isDestroyable(item)
  return not Items:IsItemLocked(item)
end

--- Fills `items` with the items of `source` that are still in the bags and that `isAvailable` accepts, up to `limit`.
--- @param source BagItem[]
--- @param isAvailable? fun(item: BagItem): boolean
--- @param items? BagItem[]
--- @param limit? integer
--- @return BagItem[] items
local function getItems(source, isAvailable, items, limit)
  updateJunkItems()

  items = items or {}
  clear(items)

  local numKept = 0
  for _, item in ipairs(source) do
    if limit and numKept >= limit then break end

    if Items:IsItemStillInBags(item) and (isAvailable == nil or isAvailable(item)) then
      numKept = numKept + 1
      items[numKept] = item
    end
  end

  return items
end

-- ============================================================================
-- JunkItemsCache
-- ============================================================================

do -- JunkItemsCache:GetVersion()
  local version = 0
  local lastCacheVersion, lastSettings, lastInclusions, lastExclusions, lastNumLevelUps

  --- The times the player has leveled up.
  local numLevelUps = 0

  -- Some items may change with the player's level, without a bag event.
  EventManager:On(E.Wow.PlayerLevelUp, function() numLevelUps = numLevelUps + 1 end)

  --- Returns a number that increases when a junk result may have changed: bag items, profile settings, global lists,
  --- or player level.
  --- @return integer
  function JunkItemsCache:GetVersion()
    local cacheVersion = BagItemsCache:GetVersion()
    local settings = StateManager:GetProfileState().settings
    local globalState = StateManager:GetGlobalState()

    if (
          cacheVersion ~= lastCacheVersion or
          settings ~= lastSettings or
          globalState.inclusions ~= lastInclusions or
          globalState.exclusions ~= lastExclusions or
          numLevelUps ~= lastNumLevelUps
        ) then
      version = version + 1
      lastCacheVersion = cacheVersion
      lastSettings = settings
      lastInclusions = globalState.inclusions
      lastExclusions = globalState.exclusions
      lastNumLevelUps = numLevelUps
    end

    return version
  end
end

--- Returns the number of sellable and destroyable junk items that are not locked. Counts again at most once per
--- `COUNT_INTERVAL_SECONDS`, unless the version changed.
--- @return integer numSellable, integer numDestroyable
function JunkItemsCache:GetNumJunkItems()
  local now = B.Utils:GetTime()
  local version = self:GetVersion()

  if version ~= Counts.version or now - Counts.time >= self.COUNT_INTERVAL_SECONDS then
    Counts.version = version
    Counts.time = now
    Counts.numSellable = #self:GetSellableJunkItems(itemsBuffer)
    Counts.numDestroyable = #self:GetDestroyableJunkItems(itemsBuffer)
  end

  return Counts.numSellable, Counts.numDestroyable
end

--- Returns the counts from `GetNumJunkItems()` as colored text: `(sellable/destroyable)`. Returns `(-/-)` until the
--- bag items have been scanned.
--- @return string
function JunkItemsCache:GetNumJunkItemsText()
  if BagItemsCache:GetVersion() == 0 then return NO_COUNTS_TEXT end

  local sellable, destroyable = self:GetNumJunkItems()
  if sellable ~= Counts.textSellable or destroyable ~= Counts.textDestroyable then
    Counts.textSellable, Counts.textDestroyable = sellable, destroyable
    Counts.text = COUNTS_TEXT_FORMAT:format(sellable, destroyable)
  end

  return Counts.text
end

--- Returns the next sellable junk item that is not locked, if one exists.
--- @return BagItem|nil
function JunkItemsCache:GetNextSellableJunkItem()
  self:GetSellableJunkItems(itemsBuffer, 1)
  return itemsBuffer[1]
end

--- Returns the next destroyable junk item that is not locked, if one exists.
--- @return BagItem|nil
function JunkItemsCache:GetNextDestroyableJunkItem()
  self:GetDestroyableJunkItems(itemsBuffer, 1)
  return itemsBuffer[1]
end

--- Returns the result of the filters for the given `item` and `filterType`, and the reason. The result is `nil` for an
--- item that is not one of the bag items.
--- @param item BagItem An item from `BagItemsCache`.
--- @param filterType ItemFilterType
--- @return ItemFilterResult? result, string? reason
function JunkItemsCache:GetResult(item, filterType)
  updateJunkItems()

  local results = filterType == "SELL" and SellResults or DestroyResults
  return results.filterResults[item], results.reasons[item]
end

--- Returns `true` if the given `item` is junk and can be sold, and the reason for the result. A junk item that
--- `JunkFilter:GetSellBlockReason()` blocks returns `false` and that reason.
--- @param item BagItem An item from `BagItemsCache`.
--- @return boolean isSellableJunk, string? reason
function JunkItemsCache:IsSellableJunkItem(item)
  updateJunkItems()

  if SellResults.filterResults[item] == ItemFilters.JUNK then
    local blockReason = JunkFilter:GetSellBlockReason(item)
    if blockReason then return false, blockReason end
    return true, SellResults.reasons[item]
  end

  return false, SellResults.reasons[item]
end

--- Returns `true` if the given `item` is junk and can be destroyed, and the reason for the result.
--- @param item BagItem An item from `BagItemsCache`.
--- @return boolean isDestroyableJunk, string? reason
function JunkItemsCache:IsDestroyableJunkItem(item)
  updateJunkItems()
  return DestroyResults.filterResults[item] == ItemFilters.JUNK, DestroyResults.reasons[item]
end

--- Returns the number of junk items for selling that cannot be sold right now.
--- @return integer
function JunkItemsCache:GetNumSellBlockedJunkItems()
  updateJunkItems()

  local numBlocked = 0
  for _, item in ipairs(SellResults.items) do
    if Items:IsItemStillInBags(item) and JunkFilter:GetSellBlockReason(item) then
      numBlocked = numBlocked + 1
    end
  end

  return numBlocked
end

--- Creates or updates an array of sellable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] sellableItems
function JunkItemsCache:GetSellableJunkItems(items, limit)
  return getItems(SellResults.items, isSellable, items, limit)
end

--- Creates or updates an array of destroyable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] destroyableItems
function JunkItemsCache:GetDestroyableJunkItems(items, limit)
  return getItems(DestroyResults.items, isDestroyable, items, limit)
end

--- Creates or updates an array of junk items, including locked ones.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] junkItems
function JunkItemsCache:GetJunkItems(items, limit)
  return getItems(junkItems, nil, items, limit)
end
