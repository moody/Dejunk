local _, Addon = ...
local Bags = Addon.Bags
local E = Addon.Events
local EventManager = Addon.EventManager

-- Initialize cache table.
Bags.cache = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local function getItem(bag, slot)
  -- GetContainerItemInfo.
  local _, quantity, _, quality, _, lootable, link, _, noValue, id = GetContainerItemInfo(bag, slot)
  if id == nil then return nil end

  -- GetItemInfo.
  local price, classId = select(11, GetItemInfo(link))
  if price == nil then
    price, classId = select(11, GetItemInfo(id))
    if price == nil then return nil end
  end

  -- Build item.
  return {
    bag = bag,
    slot = slot,
    quantity = quantity,
    quality = quality,
    lootable = lootable,
    link = link,
    noValue = noValue,
    id = id,
    price = price,
    classId = classId
  }
end

local function iterateBags()
  local bag, slot = BACKPACK_CONTAINER, 0
  local numSlots = GetContainerNumSlots(bag)

  return function()
    slot = slot + 1

    if slot > numSlots then
      slot = 1

      -- Move to next bag
      repeat
        bag = bag + 1
        if bag > NUM_BAG_SLOTS then return nil end
        numSlots = GetContainerNumSlots(bag)
      until numSlots > 0
    end

    return bag, slot, GetContainerItemID(bag, slot)
  end
end

local function updateCache()
  for k in pairs(Bags.cache) do Bags.cache[k] = nil end

  local allItemsCached = true

  for bag, slot, itemId in iterateBags() do
    if itemId then
      local item = getItem(bag, slot)
      if item then
        Bags.cache[#Bags.cache + 1] = item
      else
        allItemsCached = false
      end
    end
  end

  EventManager:Fire(E.BagsUpdated, allItemsCached)
end

-- ============================================================================
-- Events
-- ============================================================================

do
  local ticker

  EventManager:Once(E.Wow.PlayerLogin, function()
    if ticker then ticker:Cancel() end
    updateCache()
  end)

  EventManager:On(E.Wow.BagUpdateDelayed, function()
    if ticker then ticker:Cancel() end
    updateCache()
  end)

  EventManager:On(E.BagsUpdated, function(allItemsCached)
    -- If not all cached, start a new ticker to try again.
    if not allItemsCached then
      if ticker then ticker:Cancel() end
      ticker = C_Timer.NewTicker(0.25, updateCache, 1)
    end
  end)
end

-- ============================================================================
-- Bags
-- ============================================================================

function Bags:GetItem(bag, slot)
  for _, item in pairs(self.cache) do
    if item.bag == bag and item.slot == slot then
      return item
    end
  end
end

function Bags:GetItems()
  local items = {}

  -- Add cached items.
  for _, item in ipairs(self.cache) do
    items[#items + 1] = item
  end

  return items
end

function Bags:IsBagSlotEmpty(bag, slot)
  return GetContainerItemID(bag, slot) == nil
end

function Bags:IsItemStillInBags(item)
  local _, quantity, _, _, _, _, _, _, _, id = GetContainerItemInfo(item.bag, item.slot)
  return item.id == id and item.quantity == quantity
end

function Bags:IsItemLocked(item)
  local locked = select(3, GetContainerItemInfo(item.bag, item.slot))
  return locked
end

function Bags:IsItemSellable(item)
  return not item.noValue and
      item.price > 0 and
      item.quality >= Enum.ItemQuality.Poor and
      item.quality <= Enum.ItemQuality.Epic
end

function Bags:IsItemDestroyable(item)
  if Addon.IS_RETAIL and item.classId == Enum.ItemClass.Battlepet then
    return false
  end

  return item.quality >= Enum.ItemQuality.Poor and
      item.quality <= Enum.ItemQuality.Epic
end

function Bags:IsItemRefundable(item)
  local refundTimeRemaining = select(3, GetContainerItemPurchaseInfo(item.bag, item.slot))
  return refundTimeRemaining and refundTimeRemaining > 0
end
