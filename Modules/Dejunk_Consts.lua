--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_Consts: provides Dejunk modules easy access to constant values.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local GetItemClassInfo, GetItemSubClassInfo = GetItemClassInfo, GetItemSubClassInfo

-- Dejunk
local Consts = DJ.Consts

-- Called from Dejunk_Core during the PLAYER_ENTERING_WORLD event.
function Consts:Initialize()
  if self.Initialized then return end
  self.Initialized = true

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
end

--[[
//*******************************************************************
//  					    			    General Constants
//*******************************************************************
--]]

Consts.SAFE_MODE_MAX = 12

--[[
//*******************************************************************
//  					    			      UI Constants
//*******************************************************************
--]]

-- ParentFrame (these aren't used much, might remove in the future)
Consts.MIN_WIDTH = 685
Consts.MIN_HEIGHT = 390

-- The padding function exists in Tools. Is that dumb? Probably.
Consts.PADDING = 10

-- List
Consts.LIST_FRAME_MIN_WIDTH = 300
Consts.LIST_BUTTON_HEIGHT = 30
Consts.LIST_BUTTON_ICON_SIZE = 20

-- Slider
Consts.SLIDER_DEFAULT_WIDTH = 16
Consts.THUMB_DEFAULT_HEIGHT = 32

-- EditBox
Consts.EDIT_BOX_MIN_WIDTH = 75

-- ScrollFrame
Consts.SCROLL_FRAME_MIN_HEIGHT = 100

--[[
//*******************************************************************
//  					    			    Consts Functions
//*******************************************************************
--]]

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
