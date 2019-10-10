local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local floor = math.floor
local GetAverageItemLevel = _G.GetAverageItemLevel
local L = Addon.Libs.L
local LE_ITEM_ARMOR_COSMETIC = _G.LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_ARMOR_GENERIC = _G.LE_ITEM_ARMOR_GENERIC
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR
local LE_ITEM_WEAPON_FISHINGPOLE = _G.LE_ITEM_WEAPON_FISHINGPOLE
local LE_ITEM_WEAPON_GENERIC = _G.LE_ITEM_WEAPON_GENERIC
local max = math.max

-- Special check required for these generic armor types
local SPECIAL_ARMOR_EQUIPSLOTS = {
  ["INVTYPE_FINGER"] = true,
  ["INVTYPE_NECK"] = true,
  ["INVTYPE_TRINKET"] = true,
  ["INVTYPE_HOLDABLE"] = true
}

-- Returns true if the item is an equippable item; excluding generic
-- armor/weapon types, cosmetic items, and fishing poles.
-- @return {boolean}
local function isEquipmentItem(item)
  if (item.Class == Consts.ARMOR_CLASS) then
    if SPECIAL_ARMOR_EQUIPSLOTS[item.EquipSlot] then return true end
    local armorType = Consts.ARMOR_SUBCLASSES[item.SubClass]
    return (
      armorType ~= LE_ITEM_ARMOR_GENERIC and
      armorType ~= LE_ITEM_ARMOR_COSMETIC
    )
  elseif (item.Class == Consts.WEAPON_CLASS) then
    local weaponType = Consts.WEAPON_SUBCLASSES[item.SubClass]
    return (
      weaponType ~= LE_ITEM_WEAPON_GENERIC and
      weaponType ~= LE_ITEM_WEAPON_FISHINGPOLE
    )
  else
    return false
  end
end

function Filter:Run(item)
  if DB.Profile.SellBelowAverageILVL.Enabled and isEquipmentItem(item) then
    local average = floor(GetAverageItemLevel())
    local diff = max(average - DB.Profile.SellBelowAverageILVL.Value, 0)

    if (item.ItemLevel <= diff) then -- Sell
      return "JUNK", L.REASON_SELL_EQUIPMENT_BELOW_ILVL_TEXT:format(diff)
    else  -- Ignore, unless poor quality
      if (item.Quality ~= LE_ITEM_QUALITY_POOR) then
        return "NOT_JUNK", L.REASON_IGNORE_EQUIPMENT_ABOVE_ILVL_TEXT:format(diff)
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Dejunker, Filter)
