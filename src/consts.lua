-- Consts: provides Dejunk modules easy access to constant values.

local AddonName, Addon = ...

-- Upvalues
local GetItemClassInfo, GetItemSubClassInfo = GetItemClassInfo, GetItemSubClassInfo

-- Modules
local Consts = Addon.Consts

-- ============================================================================
-- General Constants
-- ============================================================================

Consts.SAFE_MODE_MAX = 12

-- SellBelowAverageILVL
Consts.BELOW_AVERAGE_ILVL_MIN = 10
Consts.BELOW_AVERAGE_ILVL_MAX = 100

-- DestroyBelowPrice
Consts.DESTROY_BELOW_PRICE_MIN = 0 -- 0 copper
Consts.DESTROY_BELOW_PRICE_MAX = 100 * 100 * 10 -- 10 gold
Consts.DESTROY_BELOW_PRICE_STEP = 10 -- 10 copper

-- ============================================================================
-- Consts Functions
-- ============================================================================

-- Called from Core during the PLAYER_ENTERING_WORLD event.
function Consts:Initialize()
  -- Player class
  self.PLAYER_CLASS = select(2, UnitClass("PLAYER"))
  self:BuildSuitables()

  -- Item classes
  self.BATTLEPET_CLASS = GetItemClassInfo(LE_ITEM_CLASS_BATTLEPET)
  self.CONSUMABLE_CLASS = GetItemClassInfo(LE_ITEM_CLASS_CONSUMABLE)
  self.GEM_CLASS = GetItemClassInfo(LE_ITEM_CLASS_GEM)
  self.GLYPH_CLASS = GetItemClassInfo(LE_ITEM_CLASS_GLYPH)
  self.ITEM_ENHANCEMENT_CLASS = GetItemClassInfo(LE_ITEM_CLASS_ITEM_ENHANCEMENT)
  self.RECIPE_CLASS = GetItemClassInfo(LE_ITEM_CLASS_RECIPE)
  self.TRADEGOODS_CLASS = GetItemClassInfo(LE_ITEM_CLASS_TRADEGOODS)

  -- Item subclasses
  self.COMPANION_SUBCLASS = GetItemSubClassInfo(LE_ITEM_CLASS_MISCELLANEOUS, 2)

  -- Armor class and subclasses
  self.ARMOR_CLASS = GetItemClassInfo(LE_ITEM_CLASS_ARMOR)
  self.ARMOR_SUBCLASSES = {}
  for i=0, (NUM_LE_ITEM_ARMORS - 1) do -- Add localized armor types to the table
    local name = GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, i)
    self.ARMOR_SUBCLASSES[name] = i
  end

  -- Weapon class and subclasses
  self.WEAPON_CLASS = GetItemClassInfo(LE_ITEM_CLASS_WEAPON)
  self.WEAPON_SUBCLASSES = {}
  for i=0, (NUM_LE_ITEM_WEAPONS - 1) do -- Add localized weapon types to the table
    local name = GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, i)
    self.WEAPON_SUBCLASSES[name] = i
  end

  -- nil functions
  self.Initialize = nil
  self.BuildSuitables = nil
end

-- Builds the SUITABLE_ARMOR and SUITABLE_WEAPONS Consts tables based on player class.
function Consts:BuildSuitables()
  local class = self.PLAYER_CLASS

  if (class == "DEATHKNIGHT") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_PLATE] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_AXE2H] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_MACE2H] = true,
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_SWORD2H] = true,
    }
  elseif (class == "DEMONHUNTER") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_LEATHER] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
      [LE_ITEM_WEAPON_WARGLAIVE] = true,
    }
  elseif (class == "DRUID") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_LEATHER] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_BEARCLAW] = true,
      [LE_ITEM_WEAPON_CATCLAW] = true,
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_MACE2H] = true,
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
    }
  elseif (class == "HUNTER") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_MAIL] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_AXE2H] = true,
      [LE_ITEM_WEAPON_BOWS] = true,
      [LE_ITEM_WEAPON_CROSSBOW] = true,
      [LE_ITEM_WEAPON_GUNS] = true,
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
    }
  elseif (class == "MAGE") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_CLOTH] = true
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_WAND] = true,
    }
  elseif (class == "MONK") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_LEATHER] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
    }
  elseif (class == "PALADIN") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_PLATE] = true,
      [LE_ITEM_ARMOR_SHIELD] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_AXE2H] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_MACE2H] = true,
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_SWORD2H] = true,
    }
  elseif (class == "PRIEST") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_CLOTH] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_WAND] = true,
    }
  elseif (class == "ROGUE") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_LEATHER] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
    }
  elseif (class == "SHAMAN") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_MAIL] = true,
      [LE_ITEM_ARMOR_SHIELD] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_AXE2H] = true,
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_MACE2H] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
    }
  elseif (class == "WARLOCK") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_CLOTH] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_DAGGER] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_WAND] = true,
    }
  elseif (class == "WARRIOR") then
    self.SUITABLE_ARMOR = {
      [LE_ITEM_ARMOR_PLATE] = true,
      [LE_ITEM_ARMOR_SHIELD] = true,
    }

    self.SUITABLE_WEAPONS = {
      [LE_ITEM_WEAPON_AXE1H] = true,
      [LE_ITEM_WEAPON_AXE2H] = true,
      [LE_ITEM_WEAPON_MACE1H] = true,
      [LE_ITEM_WEAPON_MACE2H] = true,
      [LE_ITEM_WEAPON_POLEARM] = true,
      [LE_ITEM_WEAPON_STAFF] = true,
      [LE_ITEM_WEAPON_SWORD1H] = true,
      [LE_ITEM_WEAPON_SWORD2H] = true,
      [LE_ITEM_WEAPON_UNARMED] = true,
    }
  else
    error(format("Unsupported player class: \"%s\"", class))
  end

  -- Generic suitables
  self.SUITABLE_ARMOR[LE_ITEM_ARMOR_GENERIC] = true -- Miscellaneous
  self.SUITABLE_ARMOR[LE_ITEM_ARMOR_COSMETIC] = true

  self.SUITABLE_WEAPONS[LE_ITEM_WEAPON_GENERIC] = true -- Miscellaneous
  self.SUITABLE_WEAPONS[LE_ITEM_WEAPON_FISHINGPOLE] = true
end
