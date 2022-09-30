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
  local texture, quantity, _, quality, _, lootable, link, _, noValue, id = GetContainerItemInfo(bag, slot)
  if id == nil then return nil end

  -- GetItemInfo.
  local name, _, _, itemLevel, _, _, _, _, equipLoc, _, price, classId = GetItemInfo(link)
  if name == nil then
    name, _, _, itemLevel, _, _, _, _, equipLoc, _, price, classId = GetItemInfo(id)
    if name == nil then return nil end
  end

  -- Build item.
  return {
    bag = bag,
    slot = slot,
    -- GetContainerItemInfo.
    texture = texture,
    quantity = quantity,
    quality = quality,
    lootable = lootable,
    link = link,
    noValue = noValue,
    id = id,
    -- GetItemInfo.
    name = name,
    itemLevel = GetDetailedItemLevelInfo(link) or itemLevel,
    price = price,
    classId = classId,
    -- Other.
    isBound = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot)),
    isEquippable = IsEquippableItem(link) and equipLoc ~= "INVTYPE_BAG"
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

function Bags:GetItems(items)
  if type(items) ~= "table" then
    items = {}
  else
    for k in pairs(items) do items[k] = nil end
  end

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

do -- GetAverageItemLevel()
  local slotIds = {
    INVSLOT_HEAD,
    INVSLOT_NECK,
    INVSLOT_SHOULDER,
    INVSLOT_BACK,
    INVSLOT_CHEST,
    -- INVSLOT_BODY,
    -- INVSLOT_TABARD,
    INVSLOT_WRIST,

    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
    -- INVSLOT_RANGED,
    -- INVSLOT_AMMO,

    INVSLOT_HAND,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_FINGER1,
    INVSLOT_FINGER2,
    INVSLOT_TRINKET1,
    INVSLOT_TRINKET2,
  }

  if not Addon.IS_RETAIL then
    -- slotIds[#slotIds + 1] = INVSLOT_AMMO
    slotIds[#slotIds + 1] = INVSLOT_RANGED
  end

  function Bags:GetAverageEquippedItemLevel()
    if Addon.IS_RETAIL then
      local _, averageEquippedItemLevel = GetAverageItemLevel()
      return averageEquippedItemLevel
    end

    local sumItemLevel = 0

    -- Iterate all equipped items.
    for _, slotId in pairs(slotIds) do
      local link = GetInventoryItemLink("player", slotId)
      if link then
        local itemLevel = GetDetailedItemLevelInfo(link)
        if itemLevel then
          sumItemLevel = sumItemLevel + itemLevel
        end
      end
    end

    return math.floor(sumItemLevel / #slotIds)
  end
end
