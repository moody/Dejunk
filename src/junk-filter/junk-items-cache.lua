local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager")

--- @class JunkItemsCache
local JunkItemsCache = Addon:GetModule("JunkItemsCache")

--- Seconds that `GetNumJunkItems()` keeps its counts.
--- @type number
JunkItemsCache.COUNT_INTERVAL_SECONDS = 0.25

-- ============================================================================
-- State
-- ============================================================================

--- The bag items that are junk for selling or destroying, in sort order.
--- @type BagItem[]
local junkItems = {}

--- The items in `junkItems` that are junk for selling, in sort order.
--- @type BagItem[]
local sellJunkItems = {}

--- The items in `junkItems` that are junk for destroying, in sort order.
--- @type BagItem[]
local destroyJunkItems = {}

--- The items in `junkItems` by whether they are junk for selling.
--- @type table<BagItem, boolean>
local isSellJunk = {}

--- The items in `junkItems` by whether they are junk for destroying.
--- @type table<BagItem, boolean>
local isDestroyJunk = {}

--- The bag items that are checked for junk.
--- @type BagItem[]
local bagItems = {}

--- The version that the junk items were found for.
--- @type integer?
local junkItemsVersion

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Empties the given table.
--- @param t table
local function clear(t)
  for key in pairs(t) do t[key] = nil end
end

--- Comparison function for sorting items by price, quality, and name.
--- @param a BagItem
--- @param b BagItem
--- @return boolean
local function itemSortFunc(a, b)
  local aTotalPrice = a.price * a.quantity
  local bTotalPrice = b.price * b.quantity
  if aTotalPrice == bTotalPrice then
    if a.quality == b.quality then
      if a.name == b.name then
        return a.quantity < b.quantity
      end
      return a.name < b.name
    end
    return a.quality < b.quality
  end
  return aTotalPrice < bTotalPrice
end

--- Finds the junk items again if the version changed since they were found.
local function updateJunkItems()
  local version = JunkItemsCache:GetVersion()
  if version == junkItemsVersion then return end
  junkItemsVersion = version

  clear(junkItems)
  clear(sellJunkItems)
  clear(destroyJunkItems)
  clear(isSellJunk)
  clear(isDestroyJunk)

  for _, item in ipairs(BagItemsCache:GetItems(bagItems)) do
    local isSell = JunkFilter:IsJunkItem(item, "SELL")
    local isDestroy = JunkFilter:IsJunkItem(item, "DESTROY")

    if isSell or isDestroy then
      junkItems[#junkItems + 1] = item
      isSellJunk[item] = isSell
      isDestroyJunk[item] = isDestroy
    end
  end

  table.sort(junkItems, itemSortFunc)

  for _, item in ipairs(junkItems) do
    if isSellJunk[item] then sellJunkItems[#sellJunkItems + 1] = item end
    if isDestroyJunk[item] then destroyJunkItems[#destroyJunkItems + 1] = item end
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
  local lastCacheVersion, lastSettings, lastInclusions, lastExclusions

  --- Returns a number that increases when a junk result may have changed: when the bag items changed, or the active
  --- profile's settings or a global list did.
  --- @return integer
  function JunkItemsCache:GetVersion()
    local cacheVersion = BagItemsCache:GetVersion()
    local settings = StateManager:GetProfileState().settings
    local globalState = StateManager:GetGlobalState()

    if (
          cacheVersion ~= lastCacheVersion or
          settings ~= lastSettings or
          globalState.inclusions ~= lastInclusions or
          globalState.exclusions ~= lastExclusions
        ) then
      version = version + 1
      lastCacheVersion = cacheVersion
      lastSettings = settings
      lastInclusions = globalState.inclusions
      lastExclusions = globalState.exclusions
    end

    return version
  end
end

do -- Convenience methods.
  local items = {}
  local numSellable, numDestroyable = 0, 0

  --- @type integer?
  local countedVersion

  --- @type number
  local countTime = 0

  --- Returns the number of sellable and destroyable junk items that are not locked. Counts again at most once per
  --- `COUNT_INTERVAL_SECONDS`, unless the version changed.
  --- @return integer numSellable, integer numDestroyable
  function JunkItemsCache:GetNumJunkItems()
    local now = B.Utils:GetTime()
    local version = self:GetVersion()

    if version ~= countedVersion or now - countTime >= self.COUNT_INTERVAL_SECONDS then
      countedVersion = version
      countTime = now
      numSellable = #self:GetSellableJunkItems(items)
      numDestroyable = #self:GetDestroyableJunkItems(items)
    end

    return numSellable, numDestroyable
  end

  --- Returns the next sellable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkItemsCache:GetNextSellableJunkItem()
    self:GetSellableJunkItems(items, 1)
    return items[1]
  end

  --- Returns the next destroyable junk item that is not locked, if one exists.
  --- @return BagItem|nil
  function JunkItemsCache:GetNextDestroyableJunkItem()
    self:GetDestroyableJunkItems(items, 1)
    return items[1]
  end
end

--- Returns the number of junk items for selling that cannot be sold right now.
--- @return integer
function JunkItemsCache:GetNumSellBlockedJunkItems()
  updateJunkItems()

  local numBlocked = 0
  for _, item in ipairs(sellJunkItems) do
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
  return getItems(sellJunkItems, isSellable, items, limit)
end

--- Creates or updates an array of destroyable junk items that are not locked.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] destroyableItems
function JunkItemsCache:GetDestroyableJunkItems(items, limit)
  return getItems(destroyJunkItems, isDestroyable, items, limit)
end

--- Creates or updates an array of junk items, including locked ones.
--- @param items? BagItem[]
--- @param limit? integer Keeps only the first `limit` items in sort order.
--- @return BagItem[] junkItems
function JunkItemsCache:GetJunkItems(items, limit)
  return getItems(junkItems, nil, items, limit)
end
