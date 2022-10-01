local _, Addon = ...
local E = Addon.Events
local EventManager = Addon.EventManager
local Items = Addon.Items

-- Initialize cache table.
Items.cache = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local function getItem(bag, slot)
  -- GetContainerItemInfo.
  local texture, quantity, _, quality, _, lootable, link, _, noValue, id = GetContainerItemInfo(bag, slot)
  if id == nil then return nil end

  -- GetItemInfo.
  local name, _, _, _, _, _, _, _, _, _, price, classId, subclassId = GetItemInfo(link)
  if name == nil then
    name, _, _, _, _, _, _, _, _, _, price, classId, subclassId = GetItemInfo(id)
    if name == nil then return nil end
  end

  -- Build item.
  return {
    bag = bag,
    slot = slot,
    texture = texture,
    quantity = quantity,
    quality = quality,
    lootable = lootable,
    link = link,
    noValue = noValue,
    id = id,
    name = name,
    price = price,
    classId = classId,
    subclassId = subclassId
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
  for k in pairs(Items.cache) do Items.cache[k] = nil end

  local allItemsCached = true

  for bag, slot, itemId in iterateBags() do
    if itemId then
      local item = getItem(bag, slot)
      if item then
        Items.cache[#Items.cache + 1] = item
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

function Items:GetItem(bag, slot)
  for _, item in pairs(self.cache) do
    if item.bag == bag and item.slot == slot then
      return item
    end
  end
end

function Items:GetItems(items)
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

function Items:IsBagSlotEmpty(bag, slot)
  return GetContainerItemID(bag, slot) == nil
end

function Items:IsItemStillInBags(item)
  local _, quantity, _, _, _, _, _, _, _, id = GetContainerItemInfo(item.bag, item.slot)
  return item.id == id and item.quantity == quantity
end

function Items:IsItemLocked(item)
  local locked = select(3, GetContainerItemInfo(item.bag, item.slot))
  return locked
end

function Items:IsItemSellable(item)
  return not item.noValue and
      item.price > 0 and
      item.quality >= Enum.ItemQuality.Poor and
      item.quality <= Enum.ItemQuality.Epic
end

function Items:IsItemDestroyable(item)
  if Addon.IS_RETAIL and item.classId == Enum.ItemClass.Battlepet then
    return false
  end

  return item.quality >= Enum.ItemQuality.Poor and
      item.quality <= Enum.ItemQuality.Epic
end

function Items:IsItemRefundable(item)
  local refundTimeRemaining = select(3, GetContainerItemPurchaseInfo(item.bag, item.slot))
  return refundTimeRemaining and refundTimeRemaining > 0
end

function Items:IsItemEquipment(item)
  return IsEquippableItem(item.link) and
      (item.classId == Enum.ItemClass.Armor or item.classId == Enum.ItemClass.Weapon)
end

function Items:IsItemSuitable(item)
  return self.suitable[item.classId] and self.suitable[item.classId][item.subclassId]
end

-- ============================================================================
-- Initialize
-- ============================================================================

-- Suitable items.
EventManager:Once(E.Wow.PlayerLogin, function()
  local _, class = UnitClass("player")
  local suitable = {
    -- [classId] = { [subclassId] = true }
    [Enum.ItemClass.Armor] = {},
    [Enum.ItemClass.Weapon] = {}
  }

  -- Generic armor.
  suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Generic] = true
  suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cosmetic] = true
  -- Generic weapons.
  suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Generic] = true
  suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Fishingpole] = true

  -- Warrior.
  if class == "WARRIOR" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Plate] = true
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Shield] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      -- Armor.
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
      -- Weapons.
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Crossbow] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Guns] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Thrown] = true
    end
  end

  -- Paladin.
  if class == "PALADIN" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Plate] = true
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Shield] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Libram] = true
    end
  end

  -- Hunter.
  if class == "HUNTER" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Crossbow] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Guns] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      -- Armor.
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
      -- Weapons.
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Thrown] = true
    end
  end

  -- Rogue.
  if class == "ROGUE" then
    -- Armor
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
    -- Weapons
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      -- Armor.
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      -- Weapons.
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bows] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Crossbow] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Guns] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Thrown] = true
    end
    -- Special case for one-handed axes.
    if not Addon.IS_VANILLA then
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    end
  end

  -- Priest.
  if class == "PRIEST" then
    -- Armor
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
    -- Weapons
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Wand] = true
  end

  -- Death knight.
  if class == "DEATHKNIGHT" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Plate] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = true
    -- Wrath.
    if Addon.IS_WRATH then
      -- Armor.
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Sigil] = true
    end
  end

  -- Shaman.
  if class == "SHAMAN" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Shield] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Totem] = true
    end
  end

  -- Mage/Warlock.
  if class == "MAGE" or class == "WARLOCK" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Wand] = true
  end

  -- Monk.
  if class == "MONK" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
  end

  -- Druid.
  if class == "DRUID" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    -- Classic.
    if Addon.IS_CLASSIC then
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Cloth] = true
      suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Idol] = true
    end
    -- Not Vanilla.
    if not Addon.IS_VANILLA then
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Bearclaw] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Catclaw] = true
      suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Polearm] = true
    end
  end

  -- Demon hunter.
  if class == "DEMONHUNTER" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Leather] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Warglaive] = true
  end

  -- Evoker.
  if class == "EVOKER" then
    -- Armor.
    suitable[Enum.ItemClass.Armor][Enum.ItemArmorSubclass.Mail] = true
    -- Weapons.
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Axe2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Dagger] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Mace2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Staff] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword1H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Sword2H] = true
    suitable[Enum.ItemClass.Weapon][Enum.ItemWeaponSubclass.Unarmed] = true
  end

  Items.suitable = suitable
end)
