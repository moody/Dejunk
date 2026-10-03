local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EquipmentSetsCache = Addon:GetModule("EquipmentSetsCache")
local EventManager = Addon:GetModule("EventManager")
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local GetItemSubClassInfo = C_Item.GetItemSubClassInfo or GetItemSubClassInfo
local IsCosmeticItem = C_Item.IsCosmeticItem or IsCosmeticItem
local IsEquippableItem = C_Item.IsEquippableItem or IsEquippableItem
local NUM_BAG_SLOTS = Addon.IS_RETAIL and NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
local TickerManager = Addon:GetModule("TickerManager")

--- @class Items
local Items = Addon:GetModule("Items")
Items.location = ItemLocation:CreateEmpty()

--- @type table<string, BagItem>
local bagItemCache = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the item cached for the `bag` and `slot`, if it exists.
--- @param bag integer
--- @param slot integer
--- @return BagItem
local function getCachedItem(bag, slot)
  return bagItemCache[bag .. "," .. slot]
end

--- Sets the item for the `bag` and `slot` in the cache.
--- @param bag integer
--- @param slot integer
--- @param item BagItem|nil
local function setCachedItem(bag, slot, item)
  bagItemCache[bag .. "," .. slot] = item
end

local getContainerItem
do
  --- @class BagItemInfoBuffer : ContainerItemInfo
  local t = {}

  --- Creates a new `BagItemInfo` for the given `bag` and `slot`.
  --- @param bag integer
  --- @param slot integer
  --- @return BagItemInfo? item
  function getContainerItem(bag, slot)
    --- @class BagItemInfo : table
    local item = C_Container.GetContainerItemInfo(bag, slot)
    if type(item) ~= "table" then return nil end

    for k in pairs(t) do t[k] = nil end
    for k in pairs(item) do
      t[k] = item[k]
      item[k] = nil
    end

    item.bag = bag
    item.slot = slot
    item.texture = t.iconFileID
    item.quantity = t.stackCount
    item.quality = t.quality
    item.lootable = t.hasLoot
    item.link = t.hyperlink
    item.noValue = t.hasNoValue
    item.id = t.itemID

    return item
  end
end

--- Creates a new `BagItem` for the given `bag` and `slot`.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
local function getItem(bag, slot)
  --- @class BagItem : BagItemInfo
  --- @field reason? string
  local item = getContainerItem(bag, slot)
  if item == nil then return nil end

  -- GetItemInfo.
  local name, _, _, baseItemLevel, _, _, _, _, invType, _, price, classId, subclassId = GetItemInfo(item.link)
  if name == nil then
    name, _, _, baseItemLevel, _, _, _, _, invType, _, price, classId, subclassId = GetItemInfo(item.id)
    if name == nil then return nil end
  end

  item.name = name
  item.baseItemLevel = baseItemLevel
  item.invType = invType
  item.price = price
  item.classId = classId
  item.subclassId = subclassId
  item.isEquipmentSet = EquipmentSetsCache:IsBagSlotCached(bag, slot)

  local purchaseInfo = C_Container.GetContainerItemPurchaseInfo(bag, slot, false)
  local refundSeconds = purchaseInfo and purchaseInfo.refundSeconds
  item.refundExpirationTime = refundSeconds and refundSeconds > 0 and (GetTime() + refundSeconds) or nil

  return item
end

--- Custom iterator for each bag and slot. Usage:
--- ```
--- for bag, slot, itemId in iterateBags() do
---   -- Do stuff.
--- end
--- ```
---@return function
local function iterateBags()
  local bag, slot = BACKPACK_CONTAINER, 0
  local numSlots = C_Container.GetContainerNumSlots(bag)

  return function()
    slot = slot + 1

    if slot > numSlots then
      slot = 1

      -- Move to next bag
      repeat
        bag = bag + 1
        if bag > NUM_BAG_SLOTS then return nil end
        numSlots = C_Container.GetContainerNumSlots(bag)
      until numSlots > 0
    end

    return bag, slot, C_Container.GetContainerItemID(bag, slot)
  end
end

--- Updates the item cache and fires the `BagsUpdated` event.
local function updateCache()
  EquipmentSetsCache:Refresh()

  for k in pairs(bagItemCache) do bagItemCache[k] = nil end

  local allItemsCached = true

  for bag, slot, itemId in iterateBags() do
    if itemId then
      local item = getItem(bag, slot)
      if item then
        setCachedItem(bag, slot, item)
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

-- Register events to trigger cache updates.
EventManager:Once(E.Wow.PlayerLogin, function()
  local debounce = TickerManager:NewDebouncer(0.1, updateCache)
  debounce()

  EventManager:On(E.Wow.BagUpdate, debounce)
  EventManager:On(E.Wow.BagUpdateDelayed, debounce)
  EventManager:On(E.Wow.EquipmentSetsChanged, debounce)
  EventManager:On(E.BagsUpdated, function(allItemsCached)
    if not allItemsCached then TickerManager:After(0.01, debounce) end
  end)

  -- A refund window can expire with no bag event to catch it, so poll for
  -- that and fire `BagsUpdated` when it happens.
  TickerManager:NewTicker(1, function()
    local now = GetTime()
    local anyExpired = false

    for _, item in pairs(bagItemCache) do
      if item.refundExpirationTime and item.refundExpirationTime <= now then
        item.refundExpirationTime = nil
        anyExpired = true
      end
    end

    if anyExpired then EventManager:Fire(E.BagsUpdated, true) end
  end)
end)

-- ============================================================================
-- Bags
-- ============================================================================

--- Creates a new `BagItem` for the given `bag` and `slot`.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
function Items:GetFreshItem(bag, slot)
  EquipmentSetsCache:Refresh()
  return getItem(bag, slot)
end

--- Returns a cached `BagItem` for the given `bag` and `slot`, if available.
--- @param bag integer
--- @param slot integer
--- @return BagItem? item
function Items:GetItem(bag, slot)
  return getCachedItem(bag, slot)
end

--- Creates or updates an array with all cached items.
--- @param items? BagItem[]
--- @return BagItem[] items
function Items:GetItems(items)
  if type(items) ~= "table" then
    items = {}
  else
    for k in pairs(items) do items[k] = nil end
  end

  -- Add cached items.
  for _, item in pairs(bagItemCache) do
    items[#items + 1] = item
  end

  return items
end

--- Returns `true` if the given `bag` and `slot` does not contain an item.
--- @param bag integer
--- @param slot integer
--- @return boolean
function Items:IsBagSlotEmpty(bag, slot)
  return C_Container.GetContainerItemID(bag, slot) == nil
end

--- Returns `true` if the given `item` is still in the same bag and slot.
--- @param item BagItem
--- @return boolean
function Items:IsItemStillInBags(item)
  return item.id == C_Container.GetContainerItemID(item.bag, item.slot)
end

--- Returns the given `item`'s level using `C_Item.GetCurrentItemLevel`.
--- Falls back to `GetDetailedItemLevelInfo`, then falls back to the base level.
--- @param item BagItem
--- @return number
function Items:GetItemLevel(item)
  self.location:SetBagAndSlot(item.bag, item.slot)
  local success, itemLevel = pcall(C_Item.GetCurrentItemLevel, self.location)
  if success and itemLevel then return itemLevel end
  return GetDetailedItemLevelInfo(item.link) or item.baseItemLevel
end

--- Returns the localized name of the given `item`'s subclass.
--- @param item BagItem
--- @return string
function Items:GetItemSubclassName(item)
  return (GetItemSubClassInfo(item.classId, item.subclassId))
end

--- Returns `true` if the given `item` is locked.
--- @param item BagItem
--- @return boolean
function Items:IsItemLocked(item)
  self.location:SetBagAndSlot(item.bag, item.slot)
  local success, isLocked = pcall(C_Item.IsLocked, self.location)
  if success then return isLocked end
  return true
end

--- Returns `true` if the given `item` is soulbound, account bound, or warband bound.
--- @param item BagItem
--- @return boolean
function Items:IsItemBound(item)
  self.location:SetBagAndSlot(item.bag, item.slot)

  local success, isBound = pcall(C_Item.IsBound, self.location)
  if success and isBound then return true end

  success, isBound = pcall(C_Item.IsBoundToAccountUntilEquip, self.location)
  if success and isBound then return true end

  return false
end

--- Returns `true` if the given `item` can be treated as junk.
--- @param item BagItem
--- @return boolean
function Items:IsItemJunkable(item)
  return item.quality == Enum.ItemQuality.Poor or
      item.quality == (Enum.ItemQuality.Common or Enum.ItemQuality.Standard) or
      item.quality == (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good) or
      item.quality == Enum.ItemQuality.Rare or
      item.quality == Enum.ItemQuality.Epic or
      item.quality == Enum.ItemQuality.Heirloom
end

--- Returns `true` if the given `item` can be sold.
--- @param item BagItem
--- @return boolean
function Items:IsItemSellable(item)
  return not item.noValue and item.price > 0 and self:IsItemJunkable(item)
end

--- Returns `true` if the given `item` can be destroyed.
--- @param item BagItem
--- @return boolean
function Items:IsItemDestroyable(item)
  if Addon.IS_RETAIL and item.classId == Enum.ItemClass.Battlepet then
    return false
  end

  return self:IsItemJunkable(item)
end

--- Returns `true` if the given `item` can be refunded.
--- @param item BagItem
--- @return boolean
function Items:IsItemRefundable(item)
  return item.refundExpirationTime ~= nil and item.refundExpirationTime > GetTime()
end

-- Items:IsItemEquipment()
do
  local invTypeExceptions = {
    ["INVTYPE_FINGER"] = true,
    ["INVTYPE_NECK"] = true,
    ["INVTYPE_TRINKET"] = true,
    ["INVTYPE_HOLDABLE"] = true
  }

  --- Returns `true` if the given `item` is equipment.
  --- @param item BagItem
  --- @return boolean
  function Items:IsItemEquipment(item)
    if not IsEquippableItem(item.link) then return false end
    if IsCosmeticItem and IsCosmeticItem(item.link) then return false end

    if item.classId == Enum.ItemClass.Armor then
      if invTypeExceptions[item.invType] then return true end
      return not (
        item.subclassId == Enum.ItemArmorSubclass.Generic or
        item.subclassId == Enum.ItemArmorSubclass.Cosmetic
      )
    end

    if item.classId == Enum.ItemClass.Weapon then
      return not (
        item.subclassId == Enum.ItemWeaponSubclass.Generic or
        item.subclassId == Enum.ItemWeaponSubclass.Fishingpole
      )
    end

    return false
  end
end

--- Returns `true` if the given `item` is equipment that can be placed in the warband bank.
--- @param item BagItem
--- @return boolean
function Items:IsItemWarbandEquipment(item)
  if not (Addon.IS_RETAIL and self:IsItemEquipment(item)) then return false end
  self.location:SetBagAndSlot(item.bag, item.slot)
  local success, isWarband = pcall(C_Bank.IsItemAllowedInBankType, Enum.BankType.Account, self.location)
  return (success and isWarband) or false
end

--- Returns `true` if the given `item` is an artifact relic.
--- @param item BagItem
--- @return boolean
function Items:IsItemArtifactRelic(item)
  return item.classId == Enum.ItemClass.Gem and item.subclassId == Enum.ItemGemSubclass.Artifactrelic
end
