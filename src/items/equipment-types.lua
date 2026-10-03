local Addon = select(2, ...) ---@type Addon
local GetItemSubClassInfo = C_Item and C_Item.GetItemSubClassInfo or GetItemSubClassInfo

--- @class EquipmentTypes
local EquipmentTypes = Addon:GetModule("EquipmentTypes")

-- Libram, Idol, and Totem, until Cataclysm merged them into Relic.
local HAS_CLASS_RELICS = Addon.IS_VANILLA or Addon.IS_TBC or Addon.IS_WRATH or Addon.IS_FOREVER

-- Thrown, until Mists of Pandaria removed it.
local HAS_THROWN = HAS_CLASS_RELICS or Addon.IS_CATA

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class EquipmentType
--- @field subclassId integer
--- @field name string Localized subclass name.

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the selectable armor subclasses for this game version, in display order.
--- @return integer[]
local function getArmorSubclassIds()
  local ids = {
    Enum.ItemArmorSubclass.Cloth,
    Enum.ItemArmorSubclass.Leather,
    Enum.ItemArmorSubclass.Mail,
    Enum.ItemArmorSubclass.Plate,
    Enum.ItemArmorSubclass.Shield
  }

  if HAS_CLASS_RELICS then
    ids[#ids + 1] = Enum.ItemArmorSubclass.Libram
    ids[#ids + 1] = Enum.ItemArmorSubclass.Idol
    ids[#ids + 1] = Enum.ItemArmorSubclass.Totem
  end

  if Addon.IS_WRATH then ids[#ids + 1] = Enum.ItemArmorSubclass.Sigil end
  if Addon.IS_CATA then ids[#ids + 1] = Enum.ItemArmorSubclass.Relic end

  return ids
end

--- Returns the selectable weapon subclasses for this game version, in display order.
--- @return integer[]
local function getWeaponSubclassIds()
  local ids = {
    Enum.ItemWeaponSubclass.Dagger,
    Enum.ItemWeaponSubclass.Unarmed,
    Enum.ItemWeaponSubclass.Axe1H,
    Enum.ItemWeaponSubclass.Mace1H,
    Enum.ItemWeaponSubclass.Sword1H
  }

  if Addon.IS_RETAIL then ids[#ids + 1] = Enum.ItemWeaponSubclass.Warglaive end

  ids[#ids + 1] = Enum.ItemWeaponSubclass.Axe2H
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Mace2H
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Sword2H
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Polearm
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Staff
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Bows
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Crossbow
  ids[#ids + 1] = Enum.ItemWeaponSubclass.Guns

  if HAS_THROWN then ids[#ids + 1] = Enum.ItemWeaponSubclass.Thrown end

  ids[#ids + 1] = Enum.ItemWeaponSubclass.Wand

  return ids
end

--- Returns an `EquipmentType` for each of the given subclasses.
--- @param classId integer
--- @param subclassIds integer[]
--- @return EquipmentType[]
local function toEquipmentTypes(classId, subclassIds)
  local types = {}
  for _, subclassId in ipairs(subclassIds) do
    types[#types + 1] = {
      subclassId = subclassId,
      name = GetItemSubClassInfo(classId, subclassId)
    }
  end
  return types
end

-- ============================================================================
-- EquipmentTypes
-- ============================================================================

do
  --- @type EquipmentType[]?
  local armorTypes

  --- Returns the armor types selectable in this game version, in display order.
  --- @return EquipmentType[]
  function EquipmentTypes:GetArmorTypes()
    armorTypes = armorTypes or toEquipmentTypes(Enum.ItemClass.Armor, getArmorSubclassIds())
    return armorTypes
  end
end

do
  --- @type EquipmentType[]?
  local weaponTypes

  --- Returns the weapon types selectable in this game version, in display order.
  --- @return EquipmentType[]
  function EquipmentTypes:GetWeaponTypes()
    weaponTypes = weaponTypes or toEquipmentTypes(Enum.ItemClass.Weapon, getWeaponSubclassIds())
    return weaponTypes
  end
end

--- Returns `true` if the given `item`'s armor or weapon type is selected.
--- Cloaks never match, since they are Cloth armor every class can wear.
--- @param item BagItem
--- @param armor table<integer, boolean> Selected armor subclasses.
--- @param weapons table<integer, boolean> Selected weapon subclasses.
--- @return boolean
function EquipmentTypes:IsItemTypeSelected(item, armor, weapons)
  if item.invType == "INVTYPE_CLOAK" then return false end
  if item.classId == Enum.ItemClass.Armor then return armor[item.subclassId] == true end
  if item.classId == Enum.ItemClass.Weapon then return weapons[item.subclassId] == true end
  return false
end
