local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Colors = Addon.Colors
local Consts = Addon.Consts
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Filter = {}
local Filters = Addon.Filters
local floor = math.floor
local GetAverageItemLevel = _G.GetAverageItemLevel
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L
local LE_ITEM_ARMOR_COSMETIC = _G.LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_ARMOR_GENERIC = _G.LE_ITEM_ARMOR_GENERIC
local LE_ITEM_WEAPON_FISHINGPOLE = _G.LE_ITEM_WEAPON_FISHINGPOLE
local LE_ITEM_WEAPON_GENERIC = _G.LE_ITEM_WEAPON_GENERIC
local max = math.max

local REASON = Filters:SellReason(
  L.BY_TYPE_TEXT,
  L.SELL_BELOW_AVERAGE_ILVL_TEXT .. " (%s)"
)

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
  if DB.Profile.sell.byType.belowAverageItemLevel.enabled and isEquipmentItem(item) then
    local average = floor(GetAverageItemLevel())
    local value = DB.Profile.sell.byType.belowAverageItemLevel.value
    local diff = max(average - value, 0)
    local reason = REASON:format(DCL:ColorString(value, Colors.Yellow))

    if (item.ItemLevel <= diff) then -- Sell
      return "JUNK", reason
    else  -- Ignore, unless poor quality
      if (item.Quality ~= ItemQuality.Poor) then
        return "NOT_JUNK", reason
      end
    end
  end

  return "PASS"
end

Filters:Add(Addon.Dejunker, Filter)
