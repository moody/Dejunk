local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
local GetItemSubClassInfo = C_Item.GetItemSubClassInfo or GetItemSubClassInfo
local IsCosmeticItem = C_Item.IsCosmeticItem or IsCosmeticItem
local IsEquippableItem = C_Item.IsEquippableItem or IsEquippableItem

--- @class Items
local Items = Addon:GetModule("Items")
Items.location = ItemLocation:CreateEmpty()

-- ============================================================================
-- Items
-- ============================================================================

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

--- Returns `true` if the given `item` can still be refunded. Asks the game until the item is refundable, then uses the
--- expiration time it remembered.
--- @param item BagItem
--- @return boolean
function Items:IsItemRefundable(item)
  local now = B.Utils:GetTime()
  if item.refundExpirationTime and item.refundExpirationTime > now then return true end

  local refundSeconds = B.Container:GetRefundSeconds(item.bag, item.slot)
  if refundSeconds and refundSeconds > 0 then
    item.refundExpirationTime = now + refundSeconds
    return true
  end

  return false
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
